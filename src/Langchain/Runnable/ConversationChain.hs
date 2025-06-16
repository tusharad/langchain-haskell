{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}

{- |
Module      : Langchain.Runnable.ConversationChain
Description : Stateful conversation handler for LLM interactions
Copyright   : (c) 2025 Tushar Adhatrao
License     : MIT
Maintainer  : Tushar Adhatrao <tusharadhatrao@gmail.com>

Note: This module is not functional at this moment.

This module provides the 'ConversationChain' implementation, which manages stateful
conversations with language models. It combines:

1. A memory component for storing conversation history
2. An LLM for generating responses
3. A prompt template for formatting the conversation

'ConversationChain' handles the full conversation lifecycle, including:

- Adding user messages to memory
- Retrieving conversation history
- Formatting the conversation context for the LLM
- Getting responses from the LLM
- Storing AI responses back to memory

This creates a complete conversation loop that maintains context across multiple turns.
-}
module Langchain.Runnable.ConversationChain
  ( -- * Types
    ConversationChain (..)
  ) where

import Data.Text (Text)
import Langchain.LLM.Core
import Langchain.Memory.Core
import Langchain.PromptTemplate
import Langchain.Runnable.Core

{- | Manages a stateful conversation between a user and a language model.

The 'ConversationChain' combines three key components:

1. @memory@: Stores and retrieves conversation history
2. @llm@: The language model that generates responses
3. @prompt@: Template for formatting the conversation for the LLM

When invoked with a user message, the 'ConversationChain':

- Adds the user message to memory
- Retrieves the updated conversation history
- Formats the conversation for the LLM using the prompt template
- Gets a response from the LLM
- Stores the AI response in memory
- Returns the AI response

Example:

@
import Data.Text (Text)
import qualified Data.Text as T
import Langchain.LLM.OpenAI (OpenAI(..))
import Langchain.Memory.ConversationBufferMemory (ConversationBufferMemory(..))
import Langchain.PromptTemplate (PromptTemplate(..), createPromptTemplate)
import Langchain.Runnable.ConversationChain (ConversationChain(..))

main :: IO ()
main = do
  -- Create memory component
  let memory = ConversationBufferMemory
        { messages = []
        , returnMessages = True
        }

  -- Create LLM
  let llm = OpenAI
        { model = "gpt-4"
        , temperature = 0.7
        }

  -- Create prompt template
  promptTemplate <- createPromptTemplate
    "You are a helpful assistant. {history}\\nHuman: {input}\\nAI:"
    ["history", "input"]

  -- Create conversation chain
  let conversation = ConversationChain
        { memory = memory
        , llm = llm
        , prompt = promptTemplate
        }

  -- Start conversation
  response1 <- invoke conversation "Hello, who are you?"
  case response1 of
    Left err -> putStrLn $ "Error: " ++ T.unpack err
    Right answer -> do
      putStrLn $ "AI: " ++ T.unpack answer

      -- Continue conversation with context
      response2 <- invoke conversation "What can you help me with?"
      case response2 of
        Left err -> putStrLn $ "Error: " ++ T.unpack err
        Right answer2 -> putStrLn $ "AI: " ++ T.unpack answer2
@

You can customize the behavior by using different memory implementations:

* 'ConversationBufferMemory' - Stores the full conversation history
* 'ConversationBufferWindowMemory' - Keeps only the most recent N exchanges
* 'ConversationSummaryMemory' - Summarizes older conversations to save tokens
* 'ConversationEntityMemory' - Tracks entities mentioned in the conversation

The prompt template can be customized to give the LLM specific instructions,
persona characteristics, or to format the conversation history in different ways.
-}
data ConversationChain m l = ConversationChain
  { memory :: m
  -- ^ Memory component that stores conversation history
  , llm :: l
  -- ^ Language model that generates responses
  , prompt :: PromptTemplate
  -- ^ Template for formatting the conversation
  }

-- | Make ConversationChain an instance of Runnable to enable composition with other components
instance (BaseMemory m, LLM l) => Runnable (ConversationChain m l) where
  type RunnableInput (ConversationChain m l) = Text
  type RunnableOutput (ConversationChain m l) = Text

  -- \| Process a user message and generate an AI response.
  --
  --  This method:
  --  1. Adds the user message to memory
  --  2. Retrieves the full conversation history
  --  3. Formats the history and input for the LLM
  --  4. Gets a response from the LLM
  --  5. Stores the AI response in memory
  --  6. Returns the AI response
  --
  --  Example:
  --
  --  @
  --  let chatbot = ConversationChain { ... }
  --
  --  -- Single turn conversation
  --  response <- invoke chatbot "Can you explain monads in Haskell?"
  --
  --  -- Multi-turn conversation with context
  --  response1 <- invoke chatbot "Who was Alan Turing?"
  --  response2 <- invoke chatbot "What was his most famous contribution?"
  --  response3 <- invoke chatbot "Can you explain it in simpler terms?"
  --  @
  --
  invoke ConversationChain {..} input = do
    -- Add user message to memory
    updatedMemResult <- addUserMessage memory input
    case updatedMemResult of
      Left err -> return $ Left err
      Right updatedMem -> do
        -- Get all messages
        messagesResult <- messages updatedMem
        case messagesResult of
          Left err -> return $ Left err
          Right allMessages -> do
            -- Format messages for the LLM
            let formattedMessages = allMessages
            -- Get response from LLM
            llmResponse <- chat llm formattedMessages Nothing
            case llmResponse of
              Left err -> return $ Left err
              Right response -> do
                -- Store AI response in memory
                _ <- addAiMessage updatedMem (content response)
                return $ Right (content response)
