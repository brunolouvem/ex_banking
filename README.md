# ExBanking

Banking operations over OTP application with state in memory.


## Running

Run `iex -S mix` to enter in interactive shell and call entrypoint functions in `ExBanking` module

```elixir
# Creating a new user
iex> ExBanking.create_user("John Doe")
:ok

# Deposit initial balance
ExBanking.deposit("John Doe", 100, "BRL")
{:ok, 100.0}

# Withdraw
ExBanking.withdraw("John Doe", 20.05, "BRL")
{:ok, 79.95}

# Creating other user
iex> ExBanking.create_user("Jane Doe")

# Send funds
iex> ExBanking.send("John Doe", "Jane Doe", 20, "BRL")
{:ok, 59.95, 20.0}

# Get first user balance
iex> ExBanking.get_balance("John Doe", "BRL")
{:ok, 59.95}

# Get second user balance
iex> ExBanking.get_balance("Jane Doe", "BRL")
{:ok, 20.0}
```

## Tests
Run `mix test` or `mix test --cover` to see the current test coverage.


## OTP Architecture

The following images show how the OTP structure reacts in this project.

![OTP Observer Print](images/terminal_example.png?raw=true "OTP Observer Print")

After previous command execution we can see the GenServer state reflected in `BankServer`.

![OTP Observer Print](images/observer_info.png?raw=true "OTP Observer Print")


