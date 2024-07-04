-- SETUP ********************************************
\c postgres;
DROP DATABASE IF EXISTS breaking_bad_quote_game;
CREATE DATABASE breaking_bad_quote_game;
\c breaking_bad_quote_game;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- TABLE CREATION *********************************************
CREATE TABLE users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    username VARCHAR NOT NULL UNIQUE,
    pass VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    createdAt TIMESTAMP NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMP DEFAULT NOW()
);
CREATE TABLE game (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    playedAt DATE DEFAULT NOW(),
    numberQuotes INTEGER NOT NULL,
    correctQuotes INTEGER DEFAULT 0,
    incorrectQuotes INTEGER DEFAULT 0,
    percentaje INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    finished BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES users (id)
);
CREATE TABLE quoteQuestion (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    quote VARCHAR NOT NULL,
    correctAnswer VARCHAR NOT NULL,
    givenAnswer VARCHAR NOT NULL,
    choice1 VARCHAR DEFAULT NULL,
    choice2 VARCHAR DEFAULT NULL,
    choice3 VARCHAR DEFAULT NULL,
    choice4 VARCHAR DEFAULT NULL,
    quoteOrder INTEGER NOT NULL, 
    game_id UUID REFERENCES game (id)
);

-- VIEWS *************************************************************************** 
CREATE VIEW highScores 
AS SELECT game.id as id, 
    game.playedAt as theDate, 
    game.score as score, 
    users.username as user 
FROM game JOIN users ON game.user_id=users.id 
ORDER BY game.score DESC LIMIT 15;

CREATE VIEW quotesInGames 
AS SELECT game.id as game_id, 
    game.numberQuotes,
    quoteQuestion.quote as quote, 
    quoteQuestion.correctAnswer, 
    quoteQuestion.givenAnswer, 
    quoteQuestion.choice1, 
    quoteQuestion.choice2, 
    quoteQuestion.choice3, 
    quoteQuestion.choice4,
    quoteQuestion.quoteOrder 
FROM  game JOIN quoteQuestion on quoteQuestion.game_id = game.id;

-- FUNCTIONS AND TRIGGERS ***************************************************
 
CREATE OR REPLACE FUNCTION insertUser(username_input TEXT, pass_input TEXT, email_input TEXT) 
    RETURNS TEXT
AS
$$
BEGIN
    INSERT INTO users (username, pass, email) VALUES 
    (username_input , pass_input, email_input); 
    RETURN 'USER INSERTED';
END
$$ LANGUAGE 'plpgsql';
-- 

CREATE OR REPLACE FUNCTION changeUsername(username_input TEXT,id_input UUID) 
    RETURNS TEXT
AS
$$
BEGIN
    UPDATE users
    SET username = username_input
    WHERE id=id_input;
    RETURN 'USERNAME UPDATED';
END
$$ LANGUAGE 'plpgsql';
--

CREATE OR REPLACE FUNCTION insertgame(numberQuotes_input INTEGER,user_id_input UUID) 
    RETURNS TEXT
AS
$$
BEGIN
    INSERT INTO game (numberQuotes,user_id) VALUES
    (numberQuotes_input,user_id_input);
    RETURN 'GAME INSERTED';
END
$$ LANGUAGE 'plpgsql';
--

CREATE OR REPLACE FUNCTION quitGame (id_input UUID) 
    RETURNS TEXT
AS
$$
BEGIN
    DELETE FROM game WHERE game.id = id_input;
    RETURN 'GAME DELETED';
END
$$ LANGUAGE 'plpgsql';
--

CREATE OR REPLACE FUNCTION deleteGameRelatedQuote() 
    RETURNS TRIGGER
AS
$$
BEGIN
    DELETE FROM quoteQuestion WHERE game_id = old.id;
    RETURN new;
END
$$ LANGUAGE 'plpgsql';
--

CREATE TRIGGER tr_deleteGameRelatedQuote BEFORE DELETE ON game 
FOR EACH ROW 
EXECUTE PROCEDURE deleteGameRelatedQuote();
--

CREATE OR REPLACE FUNCTION finishGame (id_input UUID, numberQuotes_input INTEGER, correctQuotes_input INTEGER, incorrectQuotes_input INTEGER, percentaje_input INTEGER, score_input INTEGER) 
    RETURNS TEXT
AS
$$
BEGIN
    UPDATE game 
    SET numberQuotes = numberQuotes_input, correctQuotes = correctQuotes_input,incorrectQuotes = incorrectQuotes_input, percentaje = percentaje_input, score = score_input, finished=TRUE
    WHERE id = id_input;
    RETURN 'GAME UPDATED';
END
$$ LANGUAGE 'plpgsql';
--

CREATE OR REPLACE FUNCTION insertQuoteQuestions(quote_input TEXT, correctAnswer_input TEXT, givenAnswer_input TEXT, quoteOrder_input INTEGER, game_id_input UUID) 
    RETURNS TEXT
AS
$$
BEGIN
    INSERT INTO quoteQuestion (quote, correctAnswer, givenAnswer, quoteOrder, game_id) VALUES
    (quote_input, correctAnswer_input, givenAnswer_input, quoteOrder_input, game_id_input);
    RETURN 'QUOTE QUESTION INSERTED';
END
$$ LANGUAGE 'plpgsql';

/*
-- Insert mock data into users table
-- Insertar usuarios
SELECT insertUser('user1', 'password1', 'user1@example.com');
SELECT insertUser('user2', 'password2', 'user2@example.com');
SELECT insertUser('user3', 'password3', 'user3@example.com');
SELECT insertUser('user4', 'password4', 'user4@example.com');
SELECT insertUser('user5', 'password5', 'user5@example.com');
-- Insertar juegos
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user1'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user1'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user2'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user2'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user3'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user3'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user4'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user4'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user5'));
SELECT insertgame(5, (SELECT id FROM users WHERE username = 'user5'));
-- Actualizar juegos
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-01'), 5, 3, 2, 60, 10);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-02'), 5, 4, 1, 80, 20);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-03'), 5, 5, 0, 100, 30);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-04'), 5, 2, 3, 40, 5);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-05'), 5, 1, 4, 20, 2);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-06'), 5, 0, 5, 0, 0);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-07'), 5, 3, 2, 60, 15);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-08'), 5, 4, 1, 80, 25);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-09'), 5, 5, 0, 100, 35);
SELECT finishGame((SELECT id FROM game WHERE playedAt = '2024-01-10'), 5, 2, 3, 40, 7);

-- Insertar preguntas de citas
SELECT insertQuoteQuestions('Quote 66', 'Correct Answer 6', 'Given Answer 6', 1, (SELECT id FROM game WHERE score = 100));
SELECT insertQuoteQuestions('Quote 50', 'Correct Answer 6', 'Given Answer 6', 1, (SELECT id FROM game WHERE score = 100));
SELECT insertQuoteQuestions('Quote 7', 'Correct Answer 7', 'Given Answer 7', 2, (SELECT id FROM game WHERE playedAt = '2024-01-02'));
SELECT insertQuoteQuestions('Quote 8', 'Correct Answer 8', 'Given Answer 8', 3, (SELECT id FROM game WHERE playedAt = '2024-01-02'));
SELECT insertQuoteQuestions('Quote 9', 'Correct Answer 9', 'Given Answer 9', 4, (SELECT id FROM game WHERE playedAt = '2024-01-02'));
SELECT insertQuoteQuestions('Quote 10', 'Correct Answer 10', 'Given Answer 10', 5, (SELECT id FROM game WHERE playedAt = '2024-01-02'));
SELECT insertQuoteQuestions('Quote 11', 'Correct Answer 11', 'Given Answer 11', 1, (SELECT id FROM game WHERE playedAt = '2024-01-03'));
SELECT insertQuoteQuestions('Quote 12', 'Correct Answer 12', 'Given Answer 12', 2, (SELECT id FROM game WHERE playedAt = '2024-01-03'));
SELECT insertQuoteQuestions('Quote 13', 'Correct Answer 13', 'Given Answer 13', 3, (SELECT id FROM game WHERE playedAt = '2024-01-03'));
SELECT insertQuoteQuestions('Quote 14', 'Correct Answer 14', 'Given Answer 14', 4, (SELECT id FROM game WHERE playedAt = '2024-01-03'));
SELECT insertQuoteQuestions('Quote 15', 'Correct Answer 15', 'Given Answer 15', 5, (SELECT id FROM game WHERE playedAt = '2024-01-03'));
SELECT insertQuoteQuestions('Quote 16', 'Correct Answer 16', 'Given Answer 16', 1, (SELECT id FROM game WHERE playedAt = '2024-01-04'));
SELECT insertQuoteQuestions('Quote 17', 'Correct Answer 17', 'Given Answer 17', 2, (SELECT id FROM game WHERE playedAt = '2024-01-04'));
SELECT insertQuoteQuestions('Quote 18', 'Correct Answer 18', 'Given Answer 18', 3, (SELECT id FROM game WHERE playedAt = '2024-01-04'));
SELECT insertQuoteQuestions('Quote 19', 'Correct Answer 19', 'Given Answer 19', 4, (SELECT id FROM game WHERE playedAt = '2024-01-04'));
SELECT insertQuoteQuestions('Quote 20', 'Correct Answer 20', 'Given Answer 20', 5, (SELECT id FROM game WHERE playedAt = '2024-01-04'));

*/