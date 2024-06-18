#!/bin/bash

ANSWER=$(( $RANDOM % 1000 + 1 ))
GUESS_COUNT=0
PSQL="psql --username=freecodecamp --dbname=number_guess -t -c"

GAME() {
  echo $1
  read GUESS
  
  # if the guess is an integer
  if [[ $GUESS =~ ^[0-9]+$ ]]
  then
    # if the guess is greater than the answer
    if (( $GUESS > $ANSWER ))
    then
      (( GUESS_COUNT++ ))
      GAME "It's lower than that, guess again:"
    # if the guess is lower than the answer
    elif (( $GUESS < $ANSWER ))
    then
      (( GUESS_COUNT++ ))
      GAME "It's higher than that, guess again:"
    # if the guess is correct
    else
      # end the game
      (( GUESS_COUNT++ ))
    fi
  else
    (( GUESS_COUNT++ ))
    GAME "That is not an integer, guess again:"
  fi
}

echo Enter your username:
read USERNAME
PLAYER_QUERY_RESULT=$($PSQL "select username, games_played, best_game from players where username = '$USERNAME'")
if [[ -z $PLAYER_QUERY_RESULT ]]
then
  echo Welcome, $USERNAME! It looks like this is your first time here.
  GAME "Guess the secret number between 1 and 1000:"
  ($PSQL "insert into players(username, games_played, best_game) values('$USERNAME', 1, $GUESS_COUNT)") > /dev/null

else
  echo $PLAYER_QUERY_RESULT | while read USERNAME BAR GAMES_PLAYED BAR BEST_GAME
  do
    echo "Welcome back, $(echo $USERNAME | sed "s/^ *| *$//")! You have played $(echo $GAMES_PLAYED | sed "s/^ *| *$//") games, and your best game took $(echo $BEST_GAME | sed "s/^ *| *$//") guesses."
  done
  
  GAME "Guess the secret number between 1 and 1000:"

  GAMES_PLAYED=$($PSQL "select games_played from players where username = '$USERNAME'")
  BEST_GAME=$($PSQL "select best_game from players where username = '$USERNAME'")
  if (( $GUESS_COUNT < $BEST_GAME ))
  then
    BEST_GAME=$GUESS_COUNT
  fi
  ($PSQL "update players set games_played = $(( $GAMES_PLAYED + 1 )), best_game = $BEST_GAME where username = '$USERNAME'") > /dev/null
fi

echo You guessed it in $GUESS_COUNT tries. The secret number was $ANSWER. Nice job!
