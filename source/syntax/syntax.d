module syntax.syntax;
import std.algorithm;

static const string [] phrasesEnd = ["?", ".", "!"];
static const char [] cutter = ['.', ',', ';', '?', '!', ':', '(', ')', ' ', '\n', '\r', '\t', '"'];
static const char [] skipper = ['\n', '\r', '\t', ' '];

string [] clean (string [] val) {
    string [] res = [];
    foreach (x ; val) {
	if (x != "") res = res ~ x;
    }
    return res;
}

string[][] cutInPhrases (string [] textWords) {
    string [][] ret = [[]];
    foreach (word ; textWords) {
	ret [$ - 1] = ret [$ - 1] ~ [word];
	if (canFind (phrasesEnd, word)) {
	    ret = ret ~ [""];
	}
    }
    return ret;
}

string[] cutInWord (string text) {
    string [] result = [""];
    foreach (j ; text) {
	if (canFind (cutter, j)) {
	    if (canFind (skipper, j)) {
		result = result ~ [""];
	    } else
		result = result ~ [j] ~ [""];
	} else if (!canFind(skipper, j)) {
	    result [$ - 1] ~= j;
	}
    }
    return result;
}
