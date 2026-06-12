-- Enable realtime for chat_message so that chatMessagesProvider (.stream())
-- receives INSERT events and the chat view updates without a manual refresh.
-- Without this, new messages are stored correctly but the stream never fires.
ALTER PUBLICATION supabase_realtime ADD TABLE chat_message;
