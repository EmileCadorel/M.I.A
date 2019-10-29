import std.stdio;
import grammar;

void main() {
    auto phrase1 = "vi misfaraĉigis bluan truon ĉe la tablo";

    writeln (phrase1.constructTree ()[0]);
    
}
