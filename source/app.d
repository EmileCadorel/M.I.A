// import std.stdio;
// import syntax._;

// void main() {
//     auto phrase1 = "vi misfaraĉigis bluan truon ĉe la tablo";

//     writeln (phrase1.constructTree ()[0]);
    
//}


import std.stdio;
import command.input;
import std.conv;
import syntax._;

void main(){
    InputLine input = new InputLine ();
    while (true) {
	auto line = input.getNextLine ().to!string;
	writeln ("");
	auto tree = line.constructTree ();
	if (tree.length != 0)
	    writeln (tree[0]);
    }
}
