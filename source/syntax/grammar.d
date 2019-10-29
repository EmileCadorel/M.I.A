/**
 * Tiu modulo kreas la arbo de sintakso el frazo
 */
module syntax.grammar;
import syntax._;
import std.algorithm;
import std.array;
import std.stdio;
import std.typecons;
import std.conv;

static string [] nt_verbs = [];
static string []  t_verbs = [];
static string []  i_words = [];
static string []  e_words = [];
static string [] ne_advs  = [];
static string [] ant_rads = [];

static this () {
    auto f = File ("resources/eo/verb-ntr.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') nt_verbs = nt_verbs ~ [line.to!string];
    }

    f = File ("resources/eo/verb-tr.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') t_verbs = t_verbs ~ [line.to!string];
    }

    f = File ("resources/eo/i_words.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') i_words = i_words ~ [line.to!string];
    }

    f = File ("resources/eo/e_words.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') e_words = e_words ~ [line.to!string];
    }
   
    f = File ("resources/eo/root-ant-at.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') ant_rads = ant_rads ~ [line.to!string];
    }

    f = File ("resources/eo/ne-advs.txt", "r");
    foreach (line ; f.byLine) {
	if (line[0] != '#') ne_advs = ne_advs ~ [line.to!string];
    }
    
}


/**
 * Se oni formaligas la gramatiko de Esperanto per ne kunteksta gramatiko, oni havas tion : 
 * Frazo -> Demando | Aserto
 * Demando -> Ki_vorto Aserto '?' | "Ĉu" Aserto '?'
 * Aserto -> Subjekto Verbo (Dativo | Predikativo)? (Dativo | Predikativo)? | 'ke' Aserto
 * Subjekto -> NomGropo 
 * Dativo -> Preposition NomGropo
 * Predikativo -> ('la')? (Adjektivo'n' ('kaj' Adjektivo'n')*)? Nomo(''')?'n' (Adjektivo'n' | Adjektivo)?
 * NomGropo -> ('la') (Adjektivo ('kaj' Adjektivo)*)? Nomo (Adjektivo)?
 */

TreeNode [] constructTree (string text) {
    auto sents = text.cutInWord ().cutInPhrases ().map! (x => x.clean).filter!(x => x != []).array;
    return constructTree (sents);
}

TreeNode[] constructTree (string [][] words) {
    TreeNode [] nodes;
    foreach (ph ; words) {
	nodes ~= constructTreeSentence (ph);
    }
    return nodes;
}

TreeNode constructTreeSentence (string [] sent) {
    if (isKiWord (sent [0])) {
	return constructTreeDemandoKi (sent);
    } else if (isCxuWord (sent [0])) {
	return constructTreeDemandoCxu (sent);
    }
    return constructTreeAserto (sent).aserto;
}

TreeNode constructTreeDemandoKi (string [] sent) {
    return null;
}

TreeNode constructTreeDemandoCxu (string [] sent) {
    return null;
}

bool getAndSetDativo (ref TreeNode node, ref string [] rest) {
    auto dat = isDativo (rest);
    node = dat.dativ;
    rest = dat.rest;
    return dat.succ;
}


bool getAndSetPredicative (ref TreeNode node, ref string [] rest) {
    auto dat = isPredicative (rest);
    node = dat.pred;
    rest = dat.rest;
    return dat.succ;
}

bool getAndSetPredicativeNTrans (ref TreeNode node, ref string [] rest) {
    auto dat = isPredicativeNTrans (rest);
    node = dat.pred;
    rest = dat.rest;
    return dat.succ;
}

bool getAndSetSubject (ref TreeNode node, ref string [] rest) {
    auto dat = isSubjekto (rest);
    node = dat.subjekto;
    rest = dat.rest;
    return dat.succ;
}

bool getAndSetVerbo (ref TreeNode node, ref string [] rest) {
    auto dat = isVerb (rest);    
    node = dat.verb;
    rest = dat.rest;
    return dat.succ;
}

Tuple!(TreeNode, "aserto", string[], "rest") constructTreeAserto (string [] sent, TreeNode pred = null, TreeNode [] dativoj = [], TreeNode sub = null, TreeNode verbo = null, bool canFinal = true) {    
    while (sent.length != 0) {
	TreeNode dat;
	if (getAndSetDativo (dat, sent)) {
	    dativoj ~= [dat];
	    continue;
	}

	if (pred is null && (verbo is null || (cast (Verb)verbo).isTransitive ()) && getAndSetPredicative (pred, sent)) {
	    writeln (pred);
	    continue;
	} else if (pred is null && verbo !is null && getAndSetPredicativeNTrans (pred, sent)) {
	    if (cast (Verb) pred !is null) {
		(cast (Verb) pred).addAttributes (verbo);
		pred = null;
	    }
	    continue;
	}
	
	if (sub is null && getAndSetSubject (sub, sent)) {
	    continue;
	}
	if (verbo is null && getAndSetVerbo (verbo, sent)) {
	    continue;
	}
	
	if (verbo !is null && canFinal) {
	    auto result = visitCompleteAdverbo (sent);
	    if (result.succ) {
		sent = result.rest;
		(cast (Verb) verbo).addAttributes (result.adv);
		continue;
	    } 
	}
	
	break;		
    }    
    
    return Tuple!(TreeNode, "aserto", string[], "rest") (new Sentence (sub, verbo, pred, dativoj), sent);
}

Tuple! (TreeNode, "aserto", string[], "rest") constructKiAsertoForNomo (string [] sent) {
    // kiu kaj kio
    if (sent.length == 0)
	return Tuple! (TreeNode, "aserto", string[], "rest") (null, sent);
    
    if (isWord (sent[0], ["kiu", "kio", "kia"], true, true)) {
	bool isPlur = sent [0].length >= 4 && sent [0][3] == 'j';
	bool isPredicative = sent [0][$-1] == 'n';
	auto nomo = new Noun (sent [0][0..3], []);
	nomo.isPlur (isPlur);
	
	if (isPredicative) {
	    auto frazo = constructTreeAserto (sent [1..$], nomo, [], null, null, false);
	    return Tuple! (TreeNode, "aserto", string[], "rest") (frazo.aserto, frazo.rest);
	} else {
	    auto frazo = constructTreeAserto (sent [1..$], null, [], nomo, null, false);
	    return Tuple! (TreeNode, "aserto", string[], "rest") (frazo.aserto, frazo.rest);
	}

    } else if (isWord (sent[0], ["kie"], true, false)) {    
	bool isMovo = sent [0][$-1] == 'n';
	auto frazo = constructTreeAserto (sent [1..$], null, [], null, null, false);
	auto nomo = new Preposition ("kie", frazo.aserto);
	if (isMovo) nomo.setType ("mov");
	else nomo.setType ("loc");
	return Tuple! (TreeNode, "aserto", string[], "rest") (nomo, frazo.rest);
    } else if (isWord (sent[0], ["kiam"], false, false)) {    
	auto frazo = constructTreeAserto (sent [1..$], null, [], null, null, false);
	auto nomo = new Preposition ("kiam", frazo.aserto);
	nomo.setType ("temp");
	return Tuple! (TreeNode, "aserto", string[], "rest") (nomo, frazo.rest);
    }

    return Tuple! (TreeNode, "aserto", string[], "rest") (null, sent);
}

bool isWord (string word, string[] poss, bool pred, bool plur) {
    int plus = 0;
    if (pred) plus ++;
    if (plur) plus ++;
    foreach (p ; poss) {
	if (word.length >= p.length && word.length <= p.length + plus) {
	    if (word [0..p.length] == p) {
		if (word.length == p.length) return true;
		if (word.length == p.length + 1) {
		    if (pred && word [$-1] == 'n') return true;
		    if (plur && word [$-1] == 'j') return true;
		}
		if (word.length == p.length + 1) {
		    if (pred && word [$-1] == 'n' && plur && word [$-2] == 'j') return true;
		}
	    }
	}
    }
    return false;
}

Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") isPredicative (string [] words) {
    auto nomo = visitCompleteNomo (words, true);
    if (nomo.succ) {
	return Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") (nomo.nomo, nomo.rest, true);
    }
    
    return Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") (null, words, false);
}

Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") isPredicativeNTrans (string [] words) {
    auto nomo = visitCompleteNomo (words, false);
    if (nomo.succ) {
	return Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") (nomo.nomo, nomo.rest, true);
    }

    auto adj = visitCompleteAdjektivo (words, false);
    if (adj.succ) {
	return Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") (adj.adj, adj.rest, true);
    }
    
    return Tuple! (TreeNode, "pred", string[], "rest", bool, "succ") (null, words, false);
}

Tuple! (TreeNode, "subjekto", string[], "rest", bool, "succ") isSubjekto (string [] words) {
    auto nomo = visitCompleteNomo (words, false);
    if (nomo.succ) {
	return Tuple! (TreeNode, "subjekto", string[], "rest", bool, "succ") (nomo.nomo, nomo.rest, true);
    }
    
    return Tuple! (TreeNode, "subjekto", string[], "rest", bool, "succ") (null, words, false);    
}

Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") isVerb (string [] words) {
    auto verb = visitCompleteVerb (words);
    if (verb.succ) {
	return Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") (verb.verb, verb.rest, true);
    }
    return  Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") (null, words, false);
}

Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") isDativo (string [] words) {
    static const string [] __movo__ = ["al", "el", "post", "preter", "tra", "trans"];
    static const string [] __loko__ = ["en", "sub", "sur", "super", "antaŭ", "malantaŭ", "inter", "ĉirkaŭ", "apud", "kontraŭ", "ekster", "ĉe", "preter"];
    static const string [] __tempo__ = ["antaŭ", "antaŭ ol", "dum", "ĝis", "post"];
    static const string [] __diversa__ = ["anstataŭ", "de", "je", "krom", "kun", "laŭ", "per", "po", "por", "pri", "pro", "sen", "sed", "do"];
    
    if (canFind (__movo__, words [0])) {
	auto mov = visitCompleteNomo (words[1..$], false);
	if (mov.succ) {
	    auto movo = new Preposition (words [0], mov.nomo);
	    movo.setType ("mov");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, mov.rest, true);
	} 
    }
    
    if (canFind (__loko__, words [0])) {
	auto loc = visitCompleteNomo (words [1..$], false);
	if (loc.succ) {
	    auto movo = new Preposition (words [0], loc.nomo);
	    movo.setType ("loc");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, loc.rest, true);
	}
	auto mov = visitCompleteNomo (words [1..$], true);
	if (mov.succ) {
	    auto movo = new Preposition (words [0], mov.nomo);
	    movo.setType ("mov");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, mov.rest, true);
	} 
    }
    
    if (canFind (__tempo__, words [0])) {
	auto loc = visitCompleteNomo (words [1..$], false);
	if (loc.succ) {
	    auto movo = new Preposition (words [0], loc.nomo);
	    movo.setType ("temp");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, loc.rest, true);
	}
	auto mov = visitCompleteNomo (words [1..$], true);
	if (mov.succ) {
	    auto movo = new Preposition (words [0], mov.nomo);
	    movo.setType ("mov temp");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, mov.rest, true);
	} 
    }
    
    if (canFind (__diversa__, words [0])) {
	auto mov = visitCompleteNomo (words[1..$], false);
	if (mov.succ) {
	    auto movo = new Preposition (words [0], mov.nomo);
	    movo.setType ("div");
	    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (movo, mov.rest, true);
	} 
    }
    
    return Tuple!(TreeNode, "dativ", string[], "rest", bool, "succ") (null, words, false);
}

Tuple!(TreeNode, "adv", string[], "rest", bool, "succ") visitCompleteAdverbo (string [] words) {
    if (words.length != 0 && isAdverbo (words [0]) && !canFind (i_words, words [0])) {
	auto adv = new Adverb (words [0], []);
	words = words [1..$];
	while (true) {
	    if (words.length > 0 && isAdverbo (words [0]) && !canFind (i_words, words [0])) {
		auto a = new Adverb (words [0], []);
		a.addAttributes (adv);
		adv = a;
		words = words[1..$];
	    } else break;
	}
	return Tuple!(TreeNode, "adv", string[], "rest", bool, "succ") (adv, words, true);
    }
    return Tuple!(TreeNode, "adv", string[], "rest", bool, "succ") (null, words, false);
}

Tuple!(TreeNode, "adj", string[], "rest", bool, "succ") visitCompleteAdjektivo (string [] words, bool predicative = false) {
    int z = 0;
    if (predicative) z = 1;

    TreeNode adv;
    auto adv_s = visitCompleteAdverbo (words);
    if (adv_s.succ) {
	adv = adv_s.adv;
	words = adv_s.rest;
    }
        
    if (words.length > 0 && isAdjektivo (words [0][0 .. $ - z]) && (!predicative || words [0][$-z] == 'n')) {
	auto adj = visitAdjektivo (words[0][0..$-z]);
	if (adv !is null)
	    (cast (Adjective) adj).addAttributes (adv);	
	return Tuple!(TreeNode, "adj", string[], "rest", bool, "succ") (adj, words[1..$], true);
    }
    
    return Tuple!(TreeNode, "adj", string[], "rest", bool, "succ") (null, words, false);
}

Tuple!(TreeNode, "nomo", string[], "rest", bool, "succ") visitCompleteNomo (string [] words, bool predicative = false) {
    int z = 0;
    bool isLa = false;   
    if (predicative) z = 1;

    if (words.length > 0 && words [0] == "la") {
	isLa = true;
	words = words [1..$];
    } else if (words.length > 0 && isPronoun (words [0][0..$-z])) {
	return Tuple!(TreeNode, "nomo", string[], "rest", bool, "succ") (visitPronoun (words[0][0..$-z]), words[1..$], true);
    }
    
    TreeNode [] adj;
    TreeNode nomo;
    
    while (true) {
	auto result = visitCompleteAdjektivo (words, predicative);
	if (result.succ) {
	    words = result.rest;
	    adj ~= result.adj;
	} else break;
	
	if (words.length > 0 && words [0] == "kaj") words = words [1..$];
    }
    
    if (words.length > 0 && isNomo (words [0][0 .. $ - z]) && (!predicative || words [0][$-z] == 'n')) {
	nomo = visitNomo (words[0][0..$-z]);
	words = words [1..$];
    } else return Tuple!(TreeNode, "nomo", string[], "rest", bool, "succ") (null, words, false);

    while (true) {
	auto result = visitCompleteAdjektivo (words, predicative);
	if (result.succ) {
	    words = result.rest;
	    adj ~= result.adj;
	} else break;
	
	if (words [0] == "kaj") words = words [1..$];
	else break;
    }

    if (words.length > 0 && words [0] == "de") {
	auto posedo = visitCompleteNomo (words[1..$], false);
	if (posedo.succ) {
	    words = posedo.rest;
	    (cast (Noun) nomo).setPosedo (posedo.nomo);
	}
    }

    // Tie ĉi, oni povas havi specialan dativon kiel "al kiu"
    // Aŭ specialaj prepozicioj komencantaj per iu 'ki' vorto
    // Povas esti 'kaj' aŭ 'aŭ' alie
    
    foreach (a ; adj)
	(cast (Noun) nomo).addAttributes (a);
    
    (cast (Noun) nomo).setIsLa (isLa);

    auto result = constructKiAsertoForNomo (words);
    if (result.aserto !is null) {
	words = result.rest;
	(cast (Noun) nomo).addAttributes (result.aserto);
    }
    
    return Tuple!(TreeNode, "nomo", string[], "rest", bool, "succ") (nomo, words, true);
}

Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") visitCompleteVerb (string [] words) {
    TreeNode adv;
    
    auto adv_s = visitCompleteAdverbo (words);
    if (adv_s.succ) {
	adv = adv_s.adv;
	words = adv_s.rest;
    }
    
    if (words.length > 0 && isVerb (words [0])) {
	auto verb = visitVerb (words [0]);
	words = words [1..$];
	
	while (words.length > 0) {
	    if (isVerb (words [0], true)) {
		auto v = visitVerb (words [0], true);
		(cast (Verb) v).addAttributes (verb);
		words = words [1..$];
		verb = v;
	    } else break;
	}

	if (adv !is null) {
	    (cast (Verb) verb).addAttributes (adv);
	}
	
	return Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") (verb, words, true);
    }
    return Tuple! (TreeNode, "verb", string[], "rest", bool, "succ") (null, words, false);
}

bool isVerb (string word, bool inf = false) {
    import std.utf;
    if (word.length <= 2) return false;
    if (canFind (i_words, word)) return false;
    if (inf) {
	if (espIsUpper (word)) return false;
	if (word [$-1] == 'i') return true;
    } else {
	if (espIsUpper (word)) return false;
	if (word [$-2..$] == "is") return true;
	if (word [$-2..$] == "as") return true;
	if (word [$-2..$] == "os") return true;
	if (word [$-2..$] == "us") return true;
	if (word [$-1..$] == "u") return true;
    }
    return false;
}

TreeNode visitVerb (string word, bool inf = false) {
    if (isVerb (word, inf)) {
	auto rad = radVerb (word);
	auto tense = tenseVerb (word);
	auto multRadTra = findInTrans (rad);
	auto multRadNTra = findInNotTrans (rad);
	if (multRadNTra.succ) {	    
	    return new Verb (multRadNTra.rad, multRadNTra.pref, multRadNTra.suff, tense, [], false);
	} else if (multRadTra.succ  && find (tense, "pass") == []) {
	    return new Verb (multRadTra.rad, multRadTra.pref, multRadTra.suff, tense, [], true);
	} else if (multRadTra.succ) {
	    return new Verb (multRadTra.rad, multRadTra.pref, multRadTra.suff, tense, [], false);
	} else { // Se oni ne konas la verbon, oni konsideras ke ĝi estas transitiva
	    return new Verb (rad, [], [], tense, [], true);
	}
    }
    return null;
}

string radVerb (string word) {
    string rest;
    if (word [$-1] == 'u' || word [$-1] == 'i')
	rest = word [0..$-1];
    else 
	rest = word [0..$-2];

    if (findInRootAnt (rest)) {
	return rest;
    }

    if (rest.length > 3) {
	auto preCon = rest [$-3..$];
	auto preCon_ = rest [$-2..$];
	if (antAtTense (preCon) != "") return rest [0..$-3];
	if (antAtTense (preCon_) != "") return rest [0..$-2];
	else return rest;
    }
    
    return rest;
}

string tenseVerb (string word) {
    string elem;
    string rest;
    if (word [$-1] == 'u' || word [$-1] == 'i') {
	elem = word [$-1..$];
	rest = word [0 .. $-1];
    } else {
	elem = word [$-2..$];
	rest = word [0 .. $-2];
    }
    
    if (findInRootAnt (rest)) {
	return simpleTense (elem);
    }
    
    if (rest.length > 3) {
	auto preCon = rest [$-3..$];
	auto preCon_ = rest [$-2..$];
	auto secTense = antAtTense (preCon);
	secTense = antAtTense (preCon_) ~ secTense;
	if (secTense != "") 
	    return secTense ~ "/" ~ simpleTense (elem);
    }
    return simpleTense (elem);
}

string antAtTense (string elem) {
    if (elem == "at") return "pass pres";
    else if (elem == "it") return "pass past";
    else if (elem == "ot") return "pass fut";
    else if (elem == "ant") return "ing pres";
    else if (elem == "int") return "ing past";
    else if (elem == "ont") return "ing fut";
    else return "";
}

string simpleTense (string elem) {
    if (elem == "as") return "pres";
    else if (elem == "os") return "fut";
    else if (elem == "is") return "past";
    else if (elem == "i") return "inf";
    else if (elem == "u") return "imp";
    else return "cond";    
}

bool findInRootAnt (string rad) {
    foreach (l ; ant_rads) {
	if (rad.length >= l.length) {
	    if (rad [$-l.length..$] == l) return true;
	}	    
    }
    return false;
}

bool isAdjektivo (string word) {
    size_t i = 0;
    if (word == "la") return false;
    if (espIsUpper (word)) return false;
    else if (word.length > 1 && word [$-1] == 'a') return true;
    else if (word.length > 2 && word [$-1] == 'j' && word [$-2] == 'a') return true;
    else return false;
}

TreeNode visitAdjektivo (string word) {    
    if (isAdjektivo (word)) {
	bool isPlur = false;
	auto elem = word [0..$-1];
	if (word [$-1] != 'a') {
	    elem = word [0..$-2];
	    isPlur = true;
	}
	
	auto rad = radVerb (elem ~ "i");
	auto tense = tenseVerb (elem ~ "i");

	if (tense.find ("/") != []) {
	    auto multRadTra = findInTrans (rad);
	    auto multRadNTra = findInNotTrans (rad);

	    if (multRadNTra.succ) {
		return new Verb (multRadNTra.rad, multRadNTra.pref, multRadNTra.suff, tense, [], false);
	    } else if (multRadTra.succ  && find (tense, "pass") == []) {
		return new Verb (multRadTra.rad, multRadTra.pref, multRadTra.suff, tense, [], true);
	    } else if (multRadTra.succ) {
		return new Verb (multRadTra.rad, multRadTra.pref, multRadTra.suff, tense, [], false);
	    } else { // Se oni ne konas la verbon, oni konsideras ke ĝi estas transitiva
		return new Verb (rad, [], [], tense, [], true);
	    }
	} else {		
	    auto adj = new Adjective (elem ~ "a", []);
	    adj.isPlur (isPlur);
	    return adj;	    
	}
    }
    return null;
}


bool isNomo (string word) {
    if (espIsUpper (word)) return true;
    else if (word.length > 1 && word [$-1] == 'o') return true;
    else if (word.length > 2 && word [$-1] == 'j' && word [$-2] == 'o') return true;
    else return false;
}

TreeNode visitNomo (string word) {
    if (isNomo (word)) {
	if (word [$-1] != 'j') 
	    return new Noun (word, []);
	else {
	    auto no = new Noun (word[0..$-1], []);
	    no.isPlur (true);
	    return no;
	}
    }
    return null;
}

bool isAdverbo (string word) {
    if (espIsUpper (word)) return false;
    else if (word.length > 1 && word [$-1] == 'e') return true;
    else if (canFind (ne_advs, word)) return true;    
    else return false;
}

TreeNode visitAdverbo (string word) {
    if (isAdverbo (word)) {
	return new Adverb (word, []);
    }
    return null;
}

bool isPronoun (string word) {
    import std.uni;
    static const string [] pronouns = ["mi", "vi", "li", "ŝi", "ĝi", "oni", "ni", "ili"];
    if (canFind (pronouns, word)) return true;
    return false;
}

TreeNode visitPronoun (string word) {
    if (isPronoun (word)) return new Pronoun (word);
    else return null;
}

bool isKiWord (string word) {
    return false;
}

bool isCxuWord (string word) {
    return false;
}

bool isNotTransitive (Verb v) {
    auto content = v.getContent ();
    return false;
}

Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") findInTrans (string verb) {
    foreach (l ; t_verbs) {
	auto res = find (verb, l[0..$-1]);// Oni forigas la fina 'i'
	if (res != "") {
	    auto end = res [l.length - 1..$];
	    auto beg = verb [0..$-(l.length + end.length - 1)];

	    auto suffs = isOnlySuff (end);
	    auto prefs = isOnlyPref (beg);
	    if (suffs.succ && prefs.succ) {
		if (!canFind (suffs.suffs, "iĝ")) {
		    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") (prefs.prefs, suffs.suffs, l, true);
		}
	    }
	}
    }
    
    foreach (l ; nt_verbs) {
	auto res = find (verb, l[0..$-1]);// Oni forigas la fina 'i'
	if (res != "") {
	    auto end = res [l.length - 1..$];
	    auto beg = verb [0..$-(l.length + end.length - 1)];

	    auto suffs = isOnlySuff (end);
	    auto prefs = isOnlyPref (beg);
	    if (suffs.succ && prefs.succ) {
		if (canFind (suffs.suffs, "ig")) {
		    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") (prefs.prefs, suffs.suffs, l, true);
		}
	    }
	}
    }    
    
    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") ([], [], "", false);
}

Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") findInNotTrans (string verb) {
    foreach (l ; nt_verbs) {
	auto res = find (verb, l[0..$-1]);// Oni forigas la fina 'i'
	if (res != "") {
	    auto end = res [l.length - 1..$];
	    auto beg = verb [0..$-(l.length + end.length - 1)];
	    
	    auto suffs = isOnlySuff (end);
	    auto prefs = isOnlyPref (beg);
	    if (suffs.succ && prefs.succ) {
		if (!canFind (suffs.suffs, "ig")) {
		    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ")
			(prefs.prefs, suffs.suffs, l, true);
		}
	    }
	}
    }

    foreach (l ; t_verbs) {
	auto res = find (verb, l[0..$-1]);// Oni forigas la fina 'i'
	if (res != "") {
	    auto end = res [l.length - 1..$];
	    auto beg = verb [0..$-(l.length + end.length - 1)];

	    auto suffs = isOnlySuff (end);
	    auto prefs = isOnlyPref (beg);
	    if (suffs.succ && prefs.succ) {
		if (canFind (suffs.suffs, "iĝ")) {
		    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ")
			(prefs.prefs, suffs.suffs, l, true);
		}
	    }
	}
    }    
    
    return Tuple! (string[], "pref", string [], "suff", string, "rad", bool, "succ") ([], [], "", false);
}

Tuple! (string[], "suffs", bool, "succ") isOnlySuff (string end) {
    auto suffs = ["ad", "aĉ", "et", "eg", "iĝ", "ig"];
    string[] res = [];
    while (true) {
	bool succ = false;
	foreach (x ; suffs) {
	    if (end.length >= x.length && end [0..x.length] == x) {
		end = end [x.length..$];
		res ~= [x];
		succ = true;		
	    }
	}
	if (succ == false) break;
    }
    if (end.length != 0) return Tuple! (string[], "suffs", bool, "succ") ([], false);
    else return Tuple! (string[], "suffs", bool, "succ") (res, true);
}

Tuple! (string[], "prefs", bool, "succ") isOnlyPref (string end) {
    auto suffs = ["mal", "ek", "mis", "fi", "re", "for", "preter"];
    string[] res = [];
    while (true) {
	bool succ = false;
	foreach (x ; suffs) {
	    if (end.length >= x.length && end [0..x.length] == x) {
		end = end [x.length..$];
		res ~= [x];	    
		succ = true;
		
	    }
	}
	if (succ == false) break;
    }
    if (end.length != 0) return Tuple! (string[], "prefs", bool, "succ") ([], false);
    else return Tuple! (string[], "prefs", bool, "succ") (res, true);
}

bool espIsUpper (string word) {
    if (word.length > 0) {
	import std.uni, std.utf;
	size_t i = 0;
	auto c = word.decode (i);
	static const dchar[] specialChar = ['ĉ', 'ĝ', 'ĥ', 'ĵ', 'ŝ', 'ŭ'];
	
	if (canFind (specialChar, c)) return false;
	return isUpper (c);
    } else return false;
}
