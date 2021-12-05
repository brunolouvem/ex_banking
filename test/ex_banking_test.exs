defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  describe "create_user/1" do
    test "create an user successfull from string" do
      assert :ok = ExBanking.create_user("Bruno Louvem")
    end

    test "don't create an user because it already exists " do
      user = "Bruno Louvem"
      assert :ok = ExBanking.create_user(user)
      assert {:error, :user_already_exists} = ExBanking.create_user(user)
    end

    test "don't create an user because name isn't a valid string " do
      assert {:error, :wrong_arguments} = ExBanking.create_user(:Bruno_Louvem)
    end
  end

  describe "deposit/3" do
    test "deposit successfull to user" do
      ExBanking.create_user("Uset Test 1")

      amount = 10.0
      assert {:ok, ^amount} = ExBanking.deposit("Uset Test 1", amount, "BRL")
    end

    test "deposit error by many requests" do
      ExBanking.create_user("User Test 2")

      test_many_requests(fn _ ->
        ExBanking.deposit("User Test 2", 100, "BRL")
      end)
    end

    test "deposit error to user because user does not exists" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("Other User Test", 1000, "BRL")
    end

    test "deposit error to user because amount is binary" do
      assert {:error, :wrong_arguments} = ExBanking.deposit("Other User Test", "1000", "BRL")
    end
  end

  describe "withdraw/3" do
    test "withdraw successfull to user" do
      ExBanking.create_user("Uset Test 3")
      ExBanking.deposit("Uset Test 3", 1000, "BRL")

      amount = 100
      assert {:ok, 900.0} = ExBanking.withdraw("Uset Test 3", amount, "BRL")
    end

    test "withdraw error by many requests" do
      ExBanking.create_user("User Test Error 3")
      ExBanking.deposit("User Test Error 3", 1000, "BRL")

      test_many_requests(fn _ ->
        ExBanking.withdraw("User Test Error 3", 10, "BRL")
      end)
    end

    test "withdraw error to user because user does not exists" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("Other User Test", 1000, "BRL")
    end

    test "withdraw error to user because amount is binary" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw("Other User Test", "1000", "BRL")
    end
  end

  describe "get_balance/3" do
    test "get_balance successfull to user" do
      ExBanking.create_user("User Test 4")
      ExBanking.deposit("User Test 4", 1000, "BRL")

      assert {:ok, 1000.0} == ExBanking.get_balance("User Test 4", "BRL")
    end

    test "get_balance successfull to user with new currency" do
      ExBanking.create_user("User Test 5")
      ExBanking.deposit("User Test 5", 1000, "BRL")

      assert {:ok, 0.0} = ExBanking.get_balance("User Test 5", "USD")
    end

    test "get_balance error by many requests" do
      ExBanking.create_user("User Test Error 5")

      test_many_requests(fn _ ->
        ExBanking.get_balance("User Test Error 5", "BRL")
      end)
    end

    test "get_balance error to user because user does not exists" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("Other User Test", "BRL")
    end

    test "get_balance error to user because currency is atom" do
      assert {:error, :wrong_arguments} = ExBanking.get_balance("User Test 5", :BRL)
    end
  end

  describe "send/4" do
    test "send successfull amount from user to other user" do
      ExBanking.create_user("User Test 6")
      ExBanking.deposit("User Test 6", 1000, "BRL")
      ExBanking.create_user("Other User Test 1")

      assert {:ok, 500.0, 500.0} = ExBanking.send("User Test 6", "Other User Test 1", 500, "BRL")
    end

    test "send successfull full amount from user to other user" do
      ExBanking.create_user("User Test 6.1")
      ExBanking.deposit("User Test 6.1", 1000, "BRL")
      ExBanking.create_user("Other User Test 1.1")

      assert {:ok, 0.0, 1000.0} =
               ExBanking.send("User Test 6.1", "Other User Test 1.1", 1000, "BRL")
    end

    test "send error to user because from user not enough money" do
      ExBanking.create_user("User Test 7")
      ExBanking.deposit("User Test 7", 1000, "BRL")
      ExBanking.create_user("Other User Test 2")

      assert {:error, :not_enough_money} =
               ExBanking.send("User Test 7", "Other User Test 2", 1500, "BRL")

      assert {:ok, 1000.0} = ExBanking.get_balance("User Test 7", "BRL")
      assert {:ok, 0.0} = ExBanking.get_balance("Other User Test 2", "BRL")
    end

    test "send error to user because receiver does not exists" do
      ExBanking.create_user("User Test 8")
      ExBanking.deposit("User Test 8", 1000, "BRL")

      assert {:error, :receiver_does_not_exist} =
               ExBanking.send("User Test 8", "Other User Test 3", 500, "BRL")
    end

    test "send error to user because sender does not exists" do
      assert {:error, :sender_does_not_exist} =
               ExBanking.send("Other User Test 3", "User Test 8", 500, "BRL")
    end

    test "send error to user because currency is atom" do
      ExBanking.create_user("Other User Test 3")

      assert {:error, :wrong_arguments} =
               ExBanking.send("User Test 8", "Other User Test 3", 500, :BRL)
    end

    test "send error by many requests sender" do
      ExBanking.create_user("User Test Error 6")
      ExBanking.deposit("User Test Error 6", 1000, "BRL")

      ExBanking.create_user("User Test 9")
      ExBanking.create_user("User Test 10")

      test_many_requests(
        fn index ->
          if rem(index, 2) == 0 do
            ExBanking.send("User Test Error 6", "User Test 9", 10, "BRL")
          else
            ExBanking.send("User Test Error 6", "User Test 10", 10, "BRL")
          end
        end,
        :too_many_requests_to_sender
      )
    end

    test "send error by many requests receiver" do
      ExBanking.create_user("User Test Error 7")

      ExBanking.create_user("User Test 11")
      ExBanking.deposit("User Test 11", 1000, "BRL")
      ExBanking.create_user("User Test 12")
      ExBanking.deposit("User Test 12", 1000, "BRL")

      test_many_requests(
        fn index ->
          if rem(index, 2) == 0 do
            ExBanking.send("User Test 11", "User Test Error 7", 100, "BRL")
          else
            ExBanking.send("User Test 12", "User Test Error 7", 100, "BRL")
          end
        end,
        :too_many_requests_to_receiver
      )
    end
  end

  defp test_many_requests(bank_function, error \\ :too_many_requests_to_user) do
    parent = self()

    for index <- 0..15 do
      Task.start(fn ->
        result = bank_function.(index)
        send(parent, {:completed, result})
      end)
    end

    result_list =
      for _ <- 0..15 do
        receive do
          {:completed, result} ->
            result
        end
      end

    assert Enum.any?(result_list, fn result ->
             {:error, error} == result
           end)
  end
end
