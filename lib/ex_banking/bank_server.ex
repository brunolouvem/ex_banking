defmodule ExBanking.BankServer do
  @moduledoc """
  Bank server responsible for the management of enqueued operations and queue state.
  """

  use GenServer

  alias ExBanking.User

  def start_link(max_user_requests) when is_number(max_user_requests) do
    GenServer.start_link(__MODULE__, max_user_requests, name: BankServer)
  end

  # Bank API

  def deposit(user, amount, currency) do
    open_transaction(user, fn ->
      User.increase_balance(user, amount, currency)
    end)
  end

  def withdraw(user, amount, currency) do
    open_transaction(user, fn ->
      User.decrease_balance(user, amount, currency)
    end)
  end

  def get_balance(user, currency) do
    open_transaction(user, fn ->
      User.get_balance(user, currency)
    end)
  end

  def send(from_user, to_user, amount, currency) do
    with {{:ok, from_balance}, _} <-
           {withdraw(from_user, amount, currency), :decrease},
         {{:ok, to_balance}, _} <-
           {deposit(to_user, amount, currency), :increase} do
      {:ok, from_balance, to_balance}
    else
      {{:error, :receiver_does_not_exist} = error, :increase} ->
        deposit(from_user, amount, currency)
        error

      {error, _} ->
        error
    end
  end

  # Callbacks

  @impl true
  def init(max_user_requests) do
    {:ok, %{max_user_requests: max_user_requests, user_requests: %{}}}
  end

  @impl true
  def handle_call({:start_transaction, user, user_function}, from, state) do
    case check_user_requests(user, state) do
      :ok ->
        user_requests = Map.get(state.user_requests, user, 0) + 1

        complete_transaction(from, user, user_function)

        user_requests_state = Map.put(state.user_requests, user, user_requests)

        {:noreply, %{state | user_requests: user_requests_state}}

      error ->
        complete_transaction(from, user, fn -> error end)

        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:transaction_completed, user}, state) do
    user_requests = Map.get(state.user_requests, user, 1) - 1

    {:noreply, %{state | user_requests: Map.put(state.user_requests, user, user_requests)}}
  end

  # Internals

  defp open_transaction(user, user_function) do
    GenServer.call(BankServer, {:start_transaction, user, user_function})
  end

  defp complete_transaction(from, user, user_function) do
    GenServer.cast(BankServer, {:transaction_completed, user})
    GenServer.reply(from, user_function.())
  end

  defp check_user_requests(user, %{
         max_user_requests: max_user_requests,
         user_requests: user_requests
       }) do
    if Map.get(user_requests, user, 0) < max_user_requests do
      :ok
    else
      handle_many_requests(user)
    end
  end

  defp handle_many_requests({:sender, _user}), do: {:error, :too_many_requests_to_sender}
  defp handle_many_requests({:receiver, _user}), do: {:error, :too_many_requests_to_receiver}
  defp handle_many_requests(_user), do: {:error, :too_many_requests_to_user}
end
