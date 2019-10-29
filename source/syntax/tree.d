/**
 * Tiu modulo enhavas la difinojn de la arbo de sintakso
 */
module syntax.tree;

import std.algorithm;
import std.outbuffer;

/**
 * TreeNode (NodArbo), estas la abstrakta klaso kiu difinas la tuta strukturo de la AAS (abstrakta arbo de sintakso)
 * Oni uzas nur la funkcio modelo, tio volas diri ke oni neniam ŝanĝas la valon de iu ajn objekto.
 */
abstract class TreeNode {
    private string _content;
        
    this (string content) {
	this._content = content;
    }    

    string prettyString () {
	return this._content;
    }

    string getContent () {
	return this._content;
    }

    string treePrintContent (string content, int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();	
	foreach (j ; 0 .. i) {
	    if (!parentLast [j]) 
		buf.write ("│   ");
	    else buf.write ("    ");
	}
	
	if (!last) 
	    buf.write ("├");
	else
	    buf.write ("└");
	
	return buf.toString  () ~ ("── ") ~ content;
    }

    
    string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();	
	foreach (j ; 0 .. i) {
	    if (!parentLast [j]) 
		buf.write ("│   ");
	    else buf.write ("    ");
	}
	
	if (!last) 
	    buf.write ("├");
	else
	    buf.write ("└");
	
	return buf.toString  () ~ ("── ") ~ this._content;
    }

    override string toString () {
	return treePrint (0);
    }
}

/++
 + =====================================================
 + ================== Basic Structure ==================
 + =====================================================
+/

/**
 * La klaso Noun (nomo) difinas ĉiujn la nomojn de la esperanta lingvo, tio volas diri ĉiujn vortojn kiuj finas per 'o', aŭ le pronomoj (vi, li, tio, tiu, ...)
 */
class Noun : TreeNode {

    private TreeNode[] _attributes;
    private TreeNode _posedo;
    bool _isLa = false;
    bool _plur = false;
    
    this (string content, TreeNode[] attrs) {
	super (content);
	this._attributes = attrs;
    }

    void addAttributes (TreeNode node) {
	this._attributes ~= node;
    }
    
    void setIsLa (bool isLa) {
	this._isLa = isLa;
    }

    void isPlur (bool pl) {
	this._plur = pl;
    }

    void setPosedo (TreeNode node) {
	this._posedo = node;
    }
    
    override string prettyString () {
	OutBuffer buf = new OutBuffer ();
	int i = 0;
	foreach (it ; this._attributes) {
	    if (i != 0)
		buf.write (" kaj ");
	    buf.write (it.prettyString);
	    i += 1;
	}
	if (_isLa) {
	    return "la " ~ buf.toString () ~ " " ~ super.prettyString ();
	} else {
	    return buf.toString () ~ " " ~ super.prettyString ();
	}
    }

    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	if (_isLa)
	    buf.writef ("%s (la)", super.treePrint (i, last, parentLast));
	else
	    buf.writef ("%s", super.treePrint (i, last, parentLast));
	
	if (_plur) buf.writefln (" (pl.)");
	else buf.writefln ("");

	if (this._posedo !is null) {
	    bool isLast = _attributes.length == 0;
	    buf.writefln ("%s", this.treePrintContent ("de ", i+1, isLast, parentLast~[last]));
	    buf.writef ("%s", this._posedo.treePrint (i+2, true, parentLast~[last]~[isLast]));
	}
	
	int z = 0;
	foreach (j ; this._attributes) {
	    z += 1;
	    buf.writef ("%s", j.treePrint (i + 1, z == this._attributes.length, parentLast ~ [last]));
	}
	return buf.toString ();
    }
}

/**
 * La klaso Adjective (Adjektivo) difinas ĉiujn la adjektivojn de la esperanta lingvo, tio volas diri ĉiujn vortojn kiuj finas per 'a'
 */
class Adjective : TreeNode {

    // Oni povas havi adverbon kiu ŝanĝas la signifo de adjektivo
    private TreeNode [] _attributes;  
    private bool _plur;
    
    this (string content, TreeNode[] attrs) {
	super (content);
	this._attributes = attrs;
    }
    
    void addAttributes (TreeNode node) {
	this._attributes ~= node;
    }

    void isPlur (bool pl) {
	this._plur = pl;
    }
    
    override string prettyString () {
	OutBuffer buf = new OutBuffer ();
	int i = 0;
	foreach (it ; this._attributes) {
	    if (i != 0)
		buf.write (" ");
	    buf.write (it.prettyString);
	    i += 1;
	}
	
	return buf.toString  () ~ super.prettyString ();
    }
    
    override string treePrint (int i = 0, bool last = false, bool[] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	buf.writef ("%s", super.treePrint (i, last, parentLast));
	if (_plur) buf.writefln (" (pl.)");
	else buf.writefln ("");
	
	int z = 0;
	foreach (j ; this._attributes) {
	    z += 1;
	    buf.writef ("%s", j.treePrint (i + 1, z == this._attributes.length, parentLast ~ [last]));
	}
	return buf.toString ();
    }
    
}


class Adverb : TreeNode {

    // Oni povas havi adverbon kiu ŝanĝas la signifo de adjektivo
    private TreeNode [] _attributes;  

    this (string content, TreeNode[] attrs) {
	super (content);
	this._attributes = attrs;
    }
    
    void addAttributes (TreeNode node) {
	this._attributes ~= node;
    }

    override string prettyString () {
	OutBuffer buf = new OutBuffer ();
	int i = 0;
	foreach (it ; this._attributes) {
	    if (i != 0)
		buf.write (" ");
	    buf.write (it.prettyString);
	    i += 1;
	}
	
	return buf.toString  () ~ super.prettyString ();
    }
    
    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	buf.writefln ("%s", super.treePrint (i, last, parentLast));

	int z = 0;
	foreach (j ; this._attributes) {
	    z += 1;
	    buf.writef ("%s", j.treePrint (i + 1, z==this._attributes.length, parentLast ~ [last]));
	}
	return buf.toString ();
    }
    
}

/**
 * La klaso Verb (verbo) difinas ĉiujn la verbojn de la esperanta lingvo, tio volas diri ĉiujn vortojn kiuj finas per 'i' aŭ kiu estas konjugita
 */
class Verb : TreeNode {

    private TreeNode [] _particles; // Particles (ekzemplo : eĉ kaj ne en la frazo 'vi ne eĉ scias tion!')
    private string _tense;
    private string[] _prefs;
    private string[] _suffs;
    private bool _trans;
    
    this (string content, string [] prefs, string [] suffs, string tense, TreeNode [] particles, bool trans) {
	super (content);
	this._particles = particles;
	this._tense = tense;
	this._prefs = prefs;
	this._suffs = suffs;
	this._trans = trans;
    }    

    void addAttributes (TreeNode n) {
	this._particles ~= [n];
    }

    bool isTransitive () {
	return this._trans;
    }
    
    override string prettyString () {
	OutBuffer buf = new OutBuffer ();
	buf.writef ("%s", _particles.map!(x => x.prettyString ()));
	buf.writef (" %s ", super.prettyString ());
		    
	return buf.toString ();
    }  
    
    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	import std.conv;
	
	OutBuffer buf = new OutBuffer ();
	buf.writefln ("%s (%s) (%s)", super.treePrint (i, last, parentLast), this._tense, this._trans? "tr." : "ntr.");
	buf.writefln ("%s (pref.)", super.treePrintContent (this._prefs.to!string, i+1, false, parentLast~[last]));
	buf.writefln ("%s (suff.)", super.treePrintContent (this._suffs.to!string, i+1, this._particles.length == 0, parentLast~[last]));
	int z = 0;
	foreach (j ; this._particles) {
	    z += 1;
	    buf.writef ("%s", j.treePrint (i + 1, z == this._particles.length, parentLast ~ [last]));
	}
	
	return buf.toString ();
    }
    
}




/**
 * La klaso Determiner (determinanto) difinas ĉiujn la determinantoj de la esperanta lingvo, tio volas diri ĉiujn la vortojn (Kiu, kia, kio ...)
 */
class Determiner : TreeNode {
    this (string content) {
	super (content);
    }   
}

/**
 * La klaso Particle (partikulo) difinas ĉiujn la partikulojn de la esperanta lingvo, tio volas diri ĉiujn la vortojn (ĉi, ĉu, ajn, eĉ, jes, ja, ne, mem)
*/
class Particle : TreeNode {
    this (string content) {
	super (content);
    }
}

class Pronoun : TreeNode {
    this (string content) {
	super (content);
    }
    
    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	buf.writefln ("%s (pr.) ", super.treePrint (i, last, parentLast));
		
	return buf.toString ();
    }
    
}

class Preposition : TreeNode {

    private TreeNode _attributes;
    private string _type;
    
    this (string content, TreeNode attrs) {
	super (content);
	this._attributes = attrs;
    }

    void setType (string type) {
	this._type = type;
    }    

    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	buf.writefln ("%s (%s.) ", super.treePrint (i, last, parentLast), _type);
		
	buf.writef ("%s", this._attributes.treePrint (i + 1, true, parentLast ~ [last]));
	return buf.toString ();
    }
}

class Sentence : TreeNode {

    private TreeNode _subjekto;
    private TreeNode _verbo;
    private TreeNode _predikativo;
    private TreeNode [] _dativoj;
    private TreeNode _intero;
    private bool _cu;

    this (TreeNode sub, TreeNode verb, TreeNode pred, TreeNode [] dat, TreeNode inter = null, bool cu = false) {
	super ("Frazo");
	this._subjekto = sub;
	this._verbo = verb;
	this._predikativo = pred;
	this._dativoj = dat;
	this._intero = inter;
	this._cu = cu;
    }

    override string treePrint (int i = 0, bool last = false, bool [] parentLast = []) {
	OutBuffer buf = new OutBuffer ();
	if (this._cu) buf.writefln ("%s (Ĉu?)", super.treePrint (i, last, parentLast));
	else if (this._intero !is null) buf.writefln ("%s?", this._intero.treePrint (i, last, parentLast));
	else buf.writefln ("%s", super.treePrint (i, last, parentLast));
	
	if (_subjekto!is null) {
	    bool isLast = _verbo is null && _predikativo is null && _dativoj.length == 0;
	    buf.writefln ("%s", this.treePrintContent ("Subjekto : ", i+1, isLast, parentLast~[last]));
	    buf.writef ("%s", this._subjekto.treePrint (i+2, true, parentLast~[last]~[isLast]));
	}

	if (_verbo!is null) {
	    bool isLast = _predikativo is null && _dativoj.length == 0;
	    buf.writefln ("%s", this.treePrintContent ("Verbo : ", i+1, isLast, parentLast~[last]));
	    buf.writef ("%s", this._verbo.treePrint (i+2, true, parentLast~[last]~[isLast]));
	}

	if (_predikativo !is null) {
	    bool isLast = _dativoj.length == 0;
	    buf.writefln ("%s", this.treePrintContent ("Predikativo : ", i+1, isLast, parentLast~[last]));
	    buf.writef ("%s", this._predikativo.treePrint (i+2, true, parentLast~[last]~[isLast]));
	}

	int z = 0;
	foreach (d ; _dativoj) {
	    z += 1;
	    buf.writefln ("%s", this.treePrintContent ("Dativo : ", i+1, _dativoj.length == z, parentLast~[last]));
	    buf.writef ("%s", d.treePrint (i+2, true, parentLast~[last]~[_dativoj.length == z]));
	}
	return buf.toString ();
    }
    
    
}
