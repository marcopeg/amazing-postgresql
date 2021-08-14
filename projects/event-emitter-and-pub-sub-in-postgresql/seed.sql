NOTIFY "ch1", '{"type":"foo", "data": "I published something in CH1"}';
NOTIFY "ch2", '{"type":"foo", "data": "I published something in CH2"}';
NOTIFY "does-not-exists", '{"it does not matter": "if a channel does not exists"}';