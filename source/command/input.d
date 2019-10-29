/**
 * Read from command line, used to create a mini tool for shell experience
*/

module command.input;
import command.terminal;

class InputLine {

    private dstring [] _history;
    private dstring _currentLine;
    private dstring _save;
    
    ulong _cursorHist = 0;
    ulong _cursor = 0;    
    ulong _lastWrite = 0;
    Terminal _terminal;
    RealTimeConsoleInput _input;
    
    this() {
	this._terminal = Terminal(ConsoleOutputType.linear); 
	this._input = RealTimeConsoleInput(&this._terminal, ConsoleInputFlags.raw); 
    }

    dstring getNextLine () {
	import std.string;
	this._terminal.write ("> ");
	while (true) {
	    auto c = this._input.getch ();

	    if (c == KeyboardEvent.Key.LeftArrow) {
		moveLeft ();
	    } else if (c == KeyboardEvent.Key.RightArrow) {
		moveRight ();
	    } else if (c == KeyboardEvent.Key.UpArrow) {
		moveUpHistory ();
	    } else if (c == KeyboardEvent.Key.DownArrow) {
		moveDownHistory ();
	    } else if (c == KeyboardEvent.Key.Delete) {
		removeCharRight ();
	    } else if (cast (int) c == 8) { // suppr
		removeCharLeft ();
	    } else if (c == '\n') break;	    
	    else addChar (c);

	    writeLine ();
	}
	
	if (strip (_currentLine) != "")
	    this._history = this._history ~ [_currentLine];
	
	this._cursorHist = this._history.length;
	
	auto res = _currentLine;
	_currentLine = "";
	_cursor = 0;
	_save = "";
	return res;
    }

    void moveDownHistory () {
	if (this._cursorHist < this._history.length) {
	    this._cursorHist += 1;
	    if (this._cursorHist == this._history.length) {
		_currentLine = _save;
	    } else
		this._currentLine = this._history [this._cursorHist];
	}
	_cursor = this._currentLine.length;
    }

    void moveUpHistory () {
	if (this._cursorHist == this._history.length) {
	    _save = _currentLine;
	}

	if (this._cursorHist > 0) {
	    this._cursorHist -= 1;
	    this._currentLine = this._history [this._cursorHist];
	}
	_cursor = this._currentLine.length;
    }
    
    void moveLeft () {
	if (_cursor > 0) this._cursor -= 1;
    }

    void moveRight () {
	if (_cursor < this._currentLine.length) this._cursor += 1;
    }
    
    void removeCharLeft () {
	if (_cursor > 0) {
	    this._currentLine = this._currentLine [0.._cursor - 1] ~ this._currentLine [_cursor .. $];
	    this._cursor -= 1;
	}
    }

    void removeCharRight () {
	if (this._cursor < this._currentLine.length) {
	    this._currentLine = this._currentLine [0.._cursor] ~ this._currentLine[_cursor + 1..$];	    
	}
    }
    
    void addChar (dchar c) {
	import std.conv;
	this._currentLine = this._currentLine [0.._cursor] ~ [c].to!dstring ~ this._currentLine [_cursor..$];
	this._cursor += 1;
    }
    
    void writeLine () {
	for (int i = 0 ; i < this._lastWrite + 2 ; i++)
	    this._terminal.write ("\b");
	for (int i = 0 ; i < this._lastWrite + 2 ; i++)
	    this._terminal.write (" ");

	for (int i = 0 ; i < this._lastWrite + 2 ; i++)
	    this._terminal.write ("\b");
	
	this._terminal.write ("> ", this._currentLine);
	this._lastWrite = this._currentLine.length;
	
	for (int i = 0 ; i < this._lastWrite + 2 ; i++)
	    this._terminal.write ("\b");
	
	this._terminal.write ("> ", this._currentLine[0.._cursor]);
	
    }

    
    
}

