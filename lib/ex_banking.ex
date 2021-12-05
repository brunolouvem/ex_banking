defmodule ExBanking do
  @moduledoc """
  Main module with all entrypoint functions.
  """
  alias ExBanking.BankServer
  alias ExBanking.User

  @doc """
  Create user from a string name.
  If it already exists or if the given name is not a valid string, an error will be raised.

  ## Examples

      iex> ExBanking.create_user("John Doe")
      :ok
      iex> ExBanking.create_user("John Doe")
      {:error, :user_already_exists}
      iex> ExBanking.create_user(:john_doe)
      {:error, :wrong_arguments}

  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case User.start_link(user) do
      {:ok, _pid} -> :ok
      {:error, _} -> {:error, :user_already_exists}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @doc """
  Deposit an amount to user in a specific currency.

  If the user has a previous balance in the given currency, the received amount will be added on it,
  otherwise the amount will be the new balance of it.

  This function enqueue an operation in BankServer. If the user has 10 pending operations by the time the enqueue operation occurs,
  this call will raise an `:too_many_requests_to_user` error.
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) do
    BankServer.deposit(user, amount, currency)
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @doc """
  Withdraw an amount from user in a specific currency.

  If user has a previous balance in the given currency, the received amount is decreased from it,
  otherwise a `:not_enough_money` error is raised.

  This function enqueue an operation in BankServer. If the user has 10 pending operations by the time the enqueue operation occurs,
  this call will raise an `:too_many_requests_to_user` error.
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) do
    BankServer.withdraw(user, amount, currency)
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @doc """
  Show the user's balance for a specific currency.
  If user does not have a balance in given currency, 0 is returned.

  This function enqueue an operation in BankServer. If the user has 10 pending operations by the time the enqueue operation occurs,
  this call will raise an `:too_many_requests_to_user` error.
  ## Examples

      iex> ExBanking.create_user("John Doe")
      :ok
      iex> ExBanking.deposit("John Doe", 1000, "usd")
      {:ok, 1000.0}
      iex> ExBanking.get_balance("John Doe", "usd")
      {:ok, 1000.0}
      iex> ExBanking.get_balance("John Doe", :usd)
      {:error, :wrong_arguments}
      iex> ExBanking.get_balance("Jane Doe", "usd")
      {:error, :user_does_not_exist}

  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency)
      when is_binary(user) and is_binary(currency) do
    BankServer.get_balance(user, currency)
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  @doc """
  Balance transfer between users in the same currency.

  This function enqueue two operations in BankServer, one for each user, and if one of the users has 10 pending operations,
  this call will raise an `:too_many_requests_to_sender` or `too_many_requests_to_receiver` error.

  This function checks the balance of the sender and, if it does not have sufficient funds, a `not_enough_money` error will be raised.
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    BankServer.send({:sender, from_user}, {:receiver, to_user}, amount, currency)
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}
end
