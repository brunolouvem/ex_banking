defmodule ExBanking.User do
  @moduledoc """
  User Agent module responsible for the user data persistence in memory, and balance operations.
  """

  use Agent

  def start_link(user) do
    Agent.start_link(fn -> %{} end, name: via_tuple(user))
  end

  @spec get_user(binary()) ::
          {:ok, map()}
          | {:error, :sender_does_not_exist | :receiver_does_not_exist | :user_does_not_exist}
  defp get_user(user) do
    try do
      user |> via_tuple() |> Agent.get(&{:ok, &1})
    catch
      :exit, _ ->
        handle_not_found_error(user)
    end
  end

  @spec get_balance(binary(), binary()) ::
          {:ok, number()}
          | {:error, :sender_does_not_exist | :receiver_does_not_exist | :user_does_not_exist}
  def get_balance(user, currency) do
    case get_user(user) do
      {:ok, found_user} ->
        balance = Map.get(found_user, currency, 0)

        {:ok, format_output_balance(balance)}

      error ->
        error
    end
  end

  @spec increase_balance(binary(), number(), binary()) ::
          {:ok, number()}
          | {:error,
             :sender_does_not_exist
             | :receiver_does_not_exist
             | :user_does_not_exist
             | :wrong_arguments}
  def increase_balance(user, amount, currency) when is_number(amount) and amount > 0 do
    case get_user(user) do
      {:ok, found_user} ->
        normalize_amount = normalize_input_amount(amount)
        current_balance = Map.get(found_user, currency, 0)
        new_balance = current_balance + normalize_amount

        user
        |> via_tuple()
        |> balance_ops(currency, new_balance)

      error ->
        error
    end
  end

  def increase_balance(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec decrease_balance(binary(), number(), binary()) ::
          {:ok, number()}
          | {:error,
             :sender_does_not_exist
             | :receiver_does_not_exist
             | :user_does_not_exist
             | :not_enough_money
             | :wrong_arguments}
  def decrease_balance(user, amount, currency) when is_number(amount) and amount > 0 do
    normalize_amount = normalize_input_amount(amount)

    with {:ok, found_user} <- get_user(user),
         {:ok, current_balance} <- Map.fetch(found_user, currency),
         {:ok, new_balance} <- validate_suficient_funds(current_balance, normalize_amount) do
      user
      |> via_tuple()
      |> balance_ops(currency, new_balance)
    else
      :error -> {:error, :not_enough_money}
      error -> error
    end
  end

  def decrease_balance(_user, _amount, _currency), do: {:error, :wrong_arguments}

  defp balance_ops(registry, currency, new_balance) do
    Agent.get_and_update(registry, fn state ->
      new_state = Map.put(state, currency, new_balance)

      {{:ok, format_output_balance(new_balance)}, new_state}
    end)
  end

  defp validate_suficient_funds(balance, amount) when balance - amount >= 0,
    do: {:ok, balance - amount}

  defp validate_suficient_funds(_balance, _amount), do: {:error, :not_enough_money}

  defp via_tuple({_, user}) do
    via_tuple(user)
  end

  defp via_tuple(user) do
    {:via, Registry, {Registry.User, user <> " Data"}}
  end

  defp handle_not_found_error({:sender, _user}), do: {:error, :sender_does_not_exist}
  defp handle_not_found_error({:receiver, _user}), do: {:error, :receiver_does_not_exist}
  defp handle_not_found_error(_user), do: {:error, :user_does_not_exist}

  defp format_output_balance(balance) do
    balance / 100
  end

  defp normalize_input_amount(amount) when is_number(amount) do
    floor(amount * 100)
  end
end
