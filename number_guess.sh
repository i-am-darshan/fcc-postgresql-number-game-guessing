#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --quiet -t --no-align -c"

echo -e "Enter your username:"
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")

if [[ -z $USER_ID ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME');"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
else
  USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS
  GUESSES=$(( GUESSES + 1 ))

  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    break
  fi
done

# User guessed correctly
echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESSES);"
$PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID;"
$PSQL "UPDATE users SET best_game = ( SELECT MIN(guesses) FROM games WHERE user_id = $USER_ID ) WHERE user_id = $USER_ID;"
exit 0 # Exit the script successfully
