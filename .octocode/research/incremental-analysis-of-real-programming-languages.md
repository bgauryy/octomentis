# Incremental Analysis of Real Programming Languages

> Source: `twagner-glr.pdf` (0 pages).

Incremental Analysis of Real Programming Languages

Tim A. Wagner and Susan L. Graham
University of California, Berkeley
Abstract
A major research goal for compilers and environments is the au-
tomatic derivation of tools from formal speciﬁcations. However,
the formal model of the language is often inadequate; in particu-
lar, LR(k) grammars are unable to describe the natural syntax of
many languages, such as C++ and Fortran, which are inherently
non-deterministic. Designers of batch compilers work around such
limitations by combining generated components with ad hoc tech-
niques (for instance, performing partial type and scope analysis in
tandem with parsing). Unfortunately, the complexity of incremen-
tal systems precludes the use of batch solutions. The inability to
generate incremental tools for important languages inhibits the
widespread use of language-rich interactive environments.
We address this problem by extending the language model it-
self, introducing a program representation based on parse dags
that is suitable for both batch and incremental analysis. Ambigu-
ities unresolved by one stage are retained in this representation
until further stages can complete the analysis, even if the resolu-
tion depends on further actions by the user. Representing ambigu-
ity explicitly increases the number and variety of languages that
can be analyzed incrementally using existing methods.
To create this representation, we have developed an efﬁcient
incremental parser for general context-free grammars. Our algo-
rithm combines Tomita’s generalized LR parser with reuse of en-
tire subtrees via state-matching. Disambiguation can occur stat-
ically, during or after parsing, or during semantic analysis (using
existing incremental techniques); program errors that preclude
disambiguation retain multiple interpretations indeﬁnitely. Our
representation and analyses gain efﬁciency by exploiting the lo-
cal nature of ambiguities: for the SPEC95 C programs, the explicit
representation of ambiguity requires only 0.5% additional space
and less than 1% additional time during reconstruction.
This research has been sponsored in part by the Defense Advanced
Research Projects Agency (DARPA) under Grant MDA972-92-J-1028. The
content of this paper does not necessarily reﬂect the position or policy of
the U. S. Government.
Authors’ addresses: Tim A. Wagner, 573 Soda Hall and Susan L. Graham,
771 Soda Hall; Department of EECS, Computer Science Division,
University of California, Berkeley, CA 94720-1776.
email: twagner@cs.berkeley.edu, graham@cs.berkeley.edu
URL: http://http.cs.berkeley.edu/˜twagner,
http://http.cs.berkeley.edu/˜graham.
1
Introduction
Generating compiler and environment components
from declarative descriptions has a number of well-
known advantages over hand-coded approaches, es-
pecially when the result is intended for an increm-
ental setting. However, existing formal methods use
limited—and unrealistic—language models. In par-
ticular, ambiguity, in both syntactic and semantic
forms, is outside the narrow constraints of LR(1)
parsing (the conventional method for syntax analy-
sis) and is not addressed by attribute grammars (the
most common form of formal semantic analysis).
Batch systems cope with such language ‘idiosyn-
crasies’ by remaining open; ad hoc code is coupled
with generated components to overcome limitations
in the language model. Those solutions succeed be-
cause the language document is static and the anal-
ysis order is ﬁxed. (For example, it can be assumed
that necessary symbol table information is available
when needed.)
The greater complexity of increm-
ental algorithms precludes simple ad hoc solutions,
due to the need to support incomplete documents and
partial analyses that depend on the order in which
the user modiﬁes the program. The result is a col-
lection of standard representations and algorithms
unable to directly model the analysis of C, C++, For-
tran, Haskell, Oberon, and many other languages.
Thus many potential applications—compilers, envi-
ronments, language-based tools—forgo incremental-
ity in favor of slower, less informative batch technolo-
gies.
Rather than lament the design of these languag-
es, we address the underlying issue by extending the
language model, producing a framework that allows
existing formalisms to apply to a wider variety of
languages. Our solution utilizes a new intermediate
representation (IR) for the early portions of the (pos-
sibly incremental) compilation pipeline: the abstract
parse dag allows multiple interpretations to be rep-
resented directly and efﬁciently. The familiar pass-
oriented compiler organization is supported, even in
incremental settings, by allowing ambiguities to be
resolved at different stages of the analysis.
Sem-
antic ﬁlters address the ‘feedback’ problem (syntac-
tic structure dependent upon semantic information)
arising in C and Fortran. Parsing ﬁlters [11] address
such problems as the declaration/expression ambi-

int foo () {
int i;
int j;
a (b);
 ambiguous—could be
c (d);
 decls or stmts.
i = 1;
j = 2;
}
Figure 1: A simple example of ambiguity in C and C++. In this
case, type information is necessary for disambiguation: the mid-
dle two lines can be either declarations or function calls, depend-
ing on how a and c have been declared previously in enclosing
scopes.
guity in C++ [3] and the ‘off-side’ rule in Haskell [7].
We describe mechanisms for applying both types of
resolution using existing formal techniques, such as
attribute grammars, while also permitting ad hoc
resolution. Pre-compiled ﬁlters such as precedence
and associativity declarations in yacc [1] are sup-
ported in a uniform fashion. In the presence of miss-
ing or malformed program text, multiple interpreta-
tions may be retained indeﬁnitely as a direct expres-
sion of the possibilities.
We have developed a novel algorithm for increm-
ental, non-deterministic parsing to (re)construct this
IR. The parser accepts all context-free grammars:
generalized LR parsing [20, 22] is used to sup-
port non-determinism and ambiguity, eliminating
restrictions on the parsing grammar and the atten-
dant need for abstraction services. Shifting of entire
subtrees via state-matching [8] provides efﬁcient in-
cremental behavior, and explicit node retention [25]
minimizes the work of subsequent analysis passes.
(Together they also ensure the preservation of user
context and program annotations.) Lookahead infor-
mation is dynamically tracked and encoded in pars-
ing states stored in the nodes, eliminating the space
overhead of previous approaches that require per-
sistent maintenance of the entire graph-structured
parse stack [4].
As an example of an inherent context-free syn-
tax ambiguity addressed by this representation, con-
sider the syntax of C. Figure 1 illustrates a case
where the interpretation of several lines is context-
sensitive, i.e., ‘static semantic’ analysis is needed to
resolve the ambiguity.
 A similar problem arises in
C++, Fortran, Oberon, and other languages.
This
problem arises whenever the natural context-free
syntax depends on non-local type information [28].
Ambiguity is discovered during analysis of the
context-free syntax, leaving multiple alternatives
encoded in the parse dag. Early stages of semantic
analysis resolve typedef declarations; binding in-
formation for type names is then used to complete
the resolution of the program’s syntax. (In the case
of a correct program, the parse dag will become a
Batch systems typically handle this problem by having the lexer query
the symbol table in order to separate identiﬁers into two distinct categories.
Attribute-inﬂuenced parsing [10, 21] is a combination of LR parsing and a
restricted class of attribute grammars that addresses the same problem in
a formal way. Neither of these solutions can be applied to an incremental
setting where non-trivial subtrees appear in the parser’s input stream.
conventional abstract parse tree.) Semantic analysis
then continues, using the resolved structure. This
approach preserves the familiar compilation pipeline
model, and allows existing formal methods to be ap-
plied to C and other ‘ill-designed’ languages to pro-
duce either batch or incremental environments.
Encoding alternatives for later resolution is use-
ful in a number of stages in the compilation pipeline.
Lexical decisions are often deferred until parsing or
semantic analysis by having the lexer recognize only
equivalence classes of tokens.
Visser [24] makes
this integration explicit for a batch system by us-
ing a single GLR parser for both lexical and context-
free analysis. This approach can be made incremen-
tal using the techniques we describe. Code genera-
tion also beneﬁts from retaining multiple represen-
tations until additional information has been gath-
ered. Giegerich [5] applies context-sharing in this
domain to intersperse code selection and register al-
location.
We have measured the space costs of our repre-
sentation and the time overhead to rebuild it incre-
mentally using a benchmark suite that includes both
C++ programs and the C programs in SPEC95. Both
measurements indicate that the signiﬁcant increase
in the ﬂexibility of the language model comes at vir-
tually no cost. The efﬁciency results from exploit-
ing an inherent property of programming (and nat-
ural) languages: ambiguity is both constrained (the
number of interpretations is small) and localized (the
length of an ambiguous construct is limited).
The remainder of this paper is organized as fol-
lows.
In Section 2 we describe the basic form of
the program representation, concentrating on the
handling of alternative interpretations.
Section 2
also summarizes empirical studies demonstrating
the highly localized nature of ambiguity in programs
and the minimal space overhead achievable through
sharing. In Section 3 we consider in detail the con-
struction of our program representation using an in-
cremental, non-deterministic parser. We introduce a
performance model and analyze the asymptotic be-
havior of the parser to demonstrate the efﬁciency
of incremental updates.
We conclude this section
with a return to the issue of sharing in the abstract
parse dag, demonstrating optimality and correct-
ness properties unique to our method. Mechanisms
for disambiguation at various points in the anal-
ysis phase—particularly semantic disambiguation
involving type information—are presented in Sec-
tion 4. Implementation details and empirical com-
parisons between deterministic parsing/parse trees
and non-deterministic parsing/abstract parse dags
are given in Section 5. A discussion of future work
and our conclusions end the paper. The incremental
GLR parsing algorithm is provided in Appendix A. A
trace of the parser actions on a small C++ example is
given in Appendix B.
2
Representing Ambiguity
A phase-oriented incremental system can succeed
only if the intermediate representation explicitly
represents unresolved ambiguities.
The abstract

42
X
A
13
B
14
C
15
a. Ferro, unambiguous case.
A
B
C
X
X->A B C
b. Rekers, unambiguous case.
B->...
C->...
A->...
X->A B C
c. Parse Dag, unambiguous case.
42
X
E
20
F
21
A
13
B
14
C
15
d. Ferro, ambiguous case.
E
F
X
A
B
C
X->A B C
X->E F
e. Rekers, ambiguous case.
X
B->...
C->...
A->...
E->...
F->...
X->A B C
X->E F
f. Parse Dag, ambiguous case.
Figure 2:
Comparison of the abstract parse dag to other proposed representations.
The grammar productions illustrated are
X!ABC
j EF. Ferro and Dion’s approach (a) makes the GSS itself persistent; this requires semantic attributes associated with a production
(right-hand side) to be attached to a constellation of nodes rather than an individual object. Rekers’ representation (b) is more like a clas-
sic parse tree but separates the symbol (phylum, left-hand side) and rule (production, right-hand side) into separate nodes. This imposes
signiﬁcant overhead, since the vast majority of the program is deterministic. Our approach represents the deterministic portions of the
tree in the conventional manner (c), using Rekers-style splitting only where multiple representations actually exist (f ). (Not shown are the
additional state collections required by the Ferro and Dion approach or the problems with under- and over-sharing of epsilon productions
eliminated in the abstract parse dag.)
item
item
int j;
j=2;
}
{
a(b);
i=1;
c(d);
int i;
decl
decl
stmt
stmt
item
item
item
items
items
items
items
block
decl
decl
stmt
stmt
item
items
Figure 3:
Representation of ambiguous structure in the ab-
stract parse dag. This is the result of parsing the example in Fig-
ure 1 as a C++ program. Most nodes represent both productions
and symbols. Choice points, shown as circles, represent only sym-
bols; their children comprise the alternative interpretations. In
this case the shared subtrees are trivial—they are the terminal
symbols in the ambiguous region. The structure shown represents
a simpliﬁcation of the complete grammar.
parse dag is similar to a parse tree except that a re-
gion may have multiple interpretations. This section
describes the representation itself; subsequent sec-
tions describe its construction, via non-deterministic
parsing, and the resolution of ambiguities expressed
through this IR.
In the presence of ambiguity, many parse trees po-
tentially represent the program. To avoid exponen-
tial blowup, this entire forest is collapsed into a sin-
gle, compact data structure. Subtree sharing merges
isomorphic regions from different trees, and requires
no special changes—each instance of a production is
represented by a single node, just as in a parse tree.
Merging contexts,
 however, requires a new type of
node to indicate the choices. A symbol node repre-
sents a phylum (left-hand side) instead of an entire
production; its children represent the possible inter-
pretations of their common yield. In the case of a
correct program, later stages of analysis will disam-
biguate the program by selecting exactly one child of
each symbol node. Figure 2 illustrates the distinc-
tion between symbol and production nodes and com-
pares our representation to other proposals. Figure 3
shows the abstract parse dag corresponding to the
example in the introduction.
If the number of alternate interpretations at a
single point is large, the children of a symbol node
can be represented as a balanced binary tree to en-
sure the performance characteristics described in
Section 3.4. In practice, however, the number of al-
ternatives is effectively bounded and a simple list
provides sufﬁciently fast access.
In a typical batch compiler, a grammar from a re-
stricted grammar class is used to produce a parser
for the concrete syntax. A separate (often implicit)
grammar deﬁnes the abstract syntax representation
Sometimes referred to as ‘packing’ in natural language analysis.

Program
Lines
Lang
%ov
compress
1934
C
0.21
gcc
205093
C
0.10
go
29246
C
0.00
ijpeg
31211
C
0.02
m88ksim
19915
C
0.02
perl
26871
C
0.01
vortex
67202
C
0.00
xlisp
7597
C
0.02
emacs 19.3
159921
C
0.47
ensemble
294204
C++
0.26
idl 1.3
29715
C++
0.10
ghostscript 3.33
128368
C
0.52
tcl 7.3
26738
C
0.31
Table 1: Programs used in this study. The ﬁrst eight are from
SPEC95. idl is the SunSoft IDL front end and ensemble is our
prototype software development environment.
of the parsed program after artifacts of the concrete
parse have been removed. GLR parsing enables a
single grammar to formally deﬁne both the repre-
sentation and the mechanism that builds it: sup-
port for multiple syntactic interpretations and non-
deterministic parsing permit arbitrary CFGs to be
used in describing the language. This generality al-
lows the grammar to serve as a pure deﬁnition of
the resulting structure, rather than requiring it to
conform to the restrictions of some particular pars-
ing class.
 Since our parse dag representation inher-
its this beneﬁt of GLR parsing, we refer to it as ‘ab-
stract’. (We will sometimes omit this modiﬁer.)
The abstract parse dag differs from the ordinary
shared forest discovered by a GLR parser: Instances
of productions are always represented by individual
nodes, and sharing of both subtrees and contexts is
optimal. We return to issues of sharing in Section 3.5
after explaining incremental GLR parsing.
2.1
Space Overhead for Ambiguity
Cognitive studies suggest that localization of ambi-
guity is an inherent property of natural languages,
a constraint imposed by limitations on short-term
memory [15, 17].
Our studies ﬁnd an identical
result for programming languages.

Since an ab-
stract parse dag exploits localization of ambiguity
through the sharing of subtrees and contexts, the in-
crease in space required relative to a fully disam-
biguated parse tree provides an ideal measure of the
amount of ambiguity (as well as the space overhead
of adopting our IR). For the suite of C and C++ pro-
grams in Table 1, we measured the increased space
consumption required to represent the multiple in-
terpretations of each syntactically ambiguous con-
Even with GLR parsing, some erasing of concrete elements unnecessary
for the abstract structure, such as parentheses, is often done.
This property was indirectly measured by Tomita [22] and Rekers [20],
who compared the speed of a batch GLR parser to Earley’s algorithm [2] on
natural and programming language grammars, respectively. Both authors
concluded that grammars are ‘close’ to LR(1) in practice, and therefore GLR
parsing exhibits linear behavior despite its exponential worst-case asymp-
totic result.
0
10
20
30
40
50
60
70
0
0.1
0.2
0.3
0.4
0.5
0.6
0.7
0.8
0.9
1
1.1
1.2
Number of gcc source files
Space increase over parse tree (%)
Figure 4: Distribution of ambiguities by source ﬁle in gcc. This
histogram groups the source ﬁles of gcc according to the amount
of syntactic ambiguity they possess. The syntax of C++ was used
to determine these counts; the percentages would be lower using
a C grammar, due to the more restrictive statement syntax of that
language. All ambiguities are semantically resolved (the ‘typedef
problem’ ). They consist of two interpretations each, and share
only terminal symbols.
struct. The increase is relative to the parse tree pro-
duced by a batch compiler (using semantic feedback
to the lexer and with the corresponding ambiguity
in the grammar resolved through different identi-
ﬁer namespaces). The average increase for each pro-
gram in the suite is shown in the ﬁnal column of Ta-
ble 1. Figure 4 shows the ambiguity distribution by
source ﬁle for gcc.
3
Constructing the Abstract Parse Dag
We now consider the construction of the abstract
parse dag via incremental, non-deterministic pars-
ing. We ﬁrst review batch GLR parsing and increm-
ental parsing, which will jointly form the basis for
the incremental GLR (IGLR) parser. We introduce a
performance model to analyze the asymptotic behav-
ior of the parser, and conclude the section by proving
that sharing in the abstract parse dag is both opti-
mal and correct. The algorithm itself appears in Ap-
pendix A.
3.1
Generalized LR Parsing
Batch GLR parsing [18, 20, 22] is a technique for
parsing arbitrary context-free grammars that uti-
lizes conventional LR table construction methods.
Unlike deterministic parsers, however, a GLR parser
permits these tables to contain conﬂicts: when a
state transition is multiply-deﬁned, the GLR parser
simply forks multiple parsers to follow each possi-
bility. In the case of a deterministic parse requir-
ing additional lookahead, all but one of these parsers
will eventually terminate by encountering a syntax
error. In the case of true ambiguity, multiple valid
representations will be discovered.
In both cases,
the graph-structured parse stack (GSS) represents
the combined parse stacks compactly. This sharing
is made possible by having the GLR parse proceed

Parser 1
Parser 2
42
0
17
23
43
z
z
U
X
x
x
V
Y
Figure 5:
Illustration of non-determinism in a GLR parser.
When the grammar is ambiguous or requires lookahead greater
than that of the table construction method (typically a single ter-
minal), a GLR parser will split into two or more parsers. Here two
parsers are being used in a region requiring two terminals of look-
ahead with an LR(1) table. (The grammar appears in Figure 7.) In
this case the parse is non-deterministic but unambiguous: when
sufﬁcient lookahead has been scanned dynamically, the GLR au-
tomaton will collapse back to a single parser. In cases of true am-
biguity, multiple interpretations are preserved in the resulting ab-
stract parse dag.
breadth-ﬁrst: each terminal symbol is shifted simul-
taneously by all active parsers in the collection. Fig-
ure 5 illustrates a GLR parser processing the non-
LR(1) grammar of Figure 7.
As demonstrated in batch environments, GLR
parsing simpliﬁes the speciﬁcation of programming
languages by removing restrictions on the parsing
grammar and eliminating the need for a separate ab-
straction mechanism. The ability to use additional
lookahead allows a more natural expression of syn-
tax and enables the description of truly ambiguous
languages.
3.2
Incremental Parsing
In an incremental parser, the input stream consists
of both terminal and nonterminal symbols; the non-
terminals label the roots of the unmodiﬁed subtrees
from the previous version of the parse tree. Two dis-
tinct approaches can be taken: sentential-form pars-
ing, where the grammar is the basis for incremen-
tality, and state-matching, where the conﬁguration
of the pushdown automaton is recorded in the tree
and used to skip steps in subsequent analyses. For
LALR or LR grammars with all conﬂicts resolved at
parse table construction time, sentential-form pars-
ing is the better implementation method, since it re-
quires less time and space than a state-matching al-
gorithm [25]. However, sentential-form parsing can-
not be used as the basis for a non-deterministic in-
cremental parser with conventional table construc-
tion: the stronger test of state-matching is needed to
expose the possibility of non-deterministic splitting
when shifting an otherwise valid subtree.
In a state-matching implementation [8, 14], each
node representing a nonterminal symbol contains a
record of the conﬁguration of the pushdown automa-
ton (the ‘parse state’ ) when the node was shifted onto
the stack. A subtree can be reused when both its
left and right context are unchanged: in an LR(1)
parser, reuse is determined by an equality test be-
tween the current parse state and the state recorded
TOS
Left (parse) Stack
Right (subtree reuse) Stack
LA
Figure 6:
Illustration of deterministic incremental parsing.
Here a change to a token has resulted in a split of the parse tree
from the root to the shaded lookahead node denoting the modi-
ﬁed terminal symbol. (Nodes on the split path are shown dashed.)
The shaded region to the left is the parse stack, which is instan-
tiated as a separate data structure since it contains a mixture
of old and new subtrees. The shaded region to the right is the
subtree reuse stack, which provides the potentially reusable sub-
trees of the parser’s input stream.
This stack is not explicitly
materialized—its contents are derived by a traversal of the parse
tree as it existed immediately prior to reparsing.
in the node, together with a check to ensure that the
same terminal symbol follows the subtree as in the
previous analysis. If the shift of a subtree is invalid,
it is decomposed into its constituent subtrees, which
are pushed back onto the input stack. This process
continues until the lookahead symbol is a terminal
or shifting can resume.
The user may apply any number of changes before
requesting a reparse. Both textual and structural
editing are permitted; the structure of the parse dag
and the contents of its terminal symbols (tokens)
reﬂects all modiﬁcations applied since the previous
parse. Once the parser is invoked, it ‘splits’ the parse
dag at each modiﬁcation point (interior nodes with
structural changes or terminal nodes with textual
changes). The input stream to the parser consists of
both new material, in the form of tokens provided by
an incremental lexer, and reused subtrees; the lat-
ter are conceptually on a stack, but are actually pro-
duced by a directed traversal over the version of the
tree as it existed immediately prior to the start of
reparsing [26]. An explicit stack is used to maintain
the new version of the tree while it is being built. Fig-
ure 6 illustrates a common case, where a changed
token has resulted in a split from the root to the
changed terminal symbol.
Shifting a subtree takes
O
() time when state-
matching succeeds. However, reductions require ex-
tra time since a terminal symbol is needed to index
the parse table. (Alternatively, the leftmost termi-
nal descendant can be recorded in every node, cost-
ing space.) Often this overhead can be eliminated en-
tirely by precomputing nonterminal reductions: we
can perform reductions with a nonterminal
N if all
reduction actions in state
s are identical for every ter-
minal in FIRST(N), provided that
N does not gener-
ate
. In the remaining cases, the lookahead’s struc-
ture must be traversed to locate the next terminal.
3.3
Incremental GLR Parsing
We now turn to the construction of an incremental
GLR (IGLR) parser that can parse an arbitrary CFG

non-deterministically, while simultaneously accept-
ing non-trivial subtrees in its input stream.
The
abstract parse dag is (re)created during parsing;
Section 3.5 explores this process in more detail.
Appendix B contains a sample trace of the IGLR
parser’s actions using our running example and a
simpliﬁed C++ grammar.
The IGLR parser combines subtree reuse in de-
terministic regions with GLR methods in areas re-
quiring non-deterministic parsing.
This aggrega-
tion of the two algorithms is complicated by the un-
constrained lookahead of non-deterministic parsing:
even though such regions are limited in practice, lo-
cating the boundary of such a region is necessary in
order to reuse unchanged subtrees.
As in previous GLR algorithms, we employ a
graph-structured parse stack (GSS) to permit non-
deterministic parsing. During parsing, determinis-
tic behavior is assumed to be the common case. (Sec-
tions 2.1 and 5 validate this assumption through
empirical measurements.) As with a deterministic
state-matching parser, each node of the parse dag
requires an additional word of storage to record the
parse state in which it was constructed. LALR(1) ta-
bles are used to drive the parser: not only are they
signiﬁcantly smaller than LR(1) tables, but they also
yield faster parsing speeds in non-deterministic re-
gions [13] and improved incremental reuse in deter-
ministic regions (due to the merging of states with
like cores).

Left context checks involve the same integer com-
parison used by a deterministic state-matching in-
cremental parser. When elements of the parse are
non-deterministic, however, the right context check
is more complicated than its deterministic counter-
part, which simply veriﬁes that the terminal sym-
bol following a potentially reusable subtree is un-
changed. For general context-free parsing, there is
no ﬁxed bound on right context; an incremental GLR
parser cannot assume that the amount of lookahead
encoded in the parse table (usually one) is sufﬁcient
to determine when a reduction’s right context is un-
changed.
Instead, the incremental GLR parser must track
lookahead use dynamically; this information is re-
corded in the nodes of the abstract parse dag, where
it is used to inﬂuence future parses. The use of ex-
tended right context can be encoded in the same ﬁeld
normally used to record the parse state. All non-de-
terministic states are represented as an equivalence
class with a unique state value. When any node pos-
sessing this state value occurs as the lookahead sym-
bol in subsequent analyses, the matching test will
fail and the parser will decompose the lookahead into
its constituent subtrees.
Additional (dynamic) lookahead is required only
when several parsers are simultaneously active. The
IGLR parsing algorithm tracks this condition with a
boolean ﬂag. After shifting the lookahead, the ﬂag
is set to true if there are multiple active parsers.
The ﬂag is also set to true when a parse table inter-
In the case where the grammar is LR but not LALR, the IGLR parser
will try all the conﬂicting reductions, resolving the uncertainty when it
shifts the following terminal symbol.
A
! Bc | De
B
! Uz
D
! Vz
U
! X
V
! Y
X
! x
Y
! x
A->Bc
z
c
B->Uz
U->X
X->x
x
Figure 7: Tracking lookahead information dynamically. This
example illustrates a grammar that requires two tokens of looka-
head. A GLR parser based on a single-lookahead table will require
non-determinism to parse the sentence xzc. Since the grammar
is unambiguous, a unique parse tree results after c is read. The
unsuccessful parser is discarded. Black ellipses indicate nodes for
which increased lookahead must be recorded during parsing; note
that they coincide with reductions performed while more than one
parser was active.
Nonterminals representing reductions in a
deterministic state (A!Bc) require only the implicit (one token)
lookahead; they are marked with the (singleton) parser’s state
when they are shifted onto its parse stack.
rogation returns multiple actions. During a reduc-
tion, the state value recorded in the newly-created
dag node is the state of the single active parser, if
the ﬂag is false, and the value representing all non-
deterministic states (and thus the use of additional
lookahead), if the ﬂag is true. Figure 7 shows a sim-
ple case where dynamic lookahead is used by our
IGLR parser to analyze an LR(2) grammar using
LR(1) tables.
When both the previous state (preserved in the
root node of the lookahead subtree) and the cur-
rent state are deterministic, parsing proceeds as
in Section 3.2. Shifted subtrees may contain non-
deterministic areas as long as they are not ex-
posed.
Subtrees containing modiﬁcations (textual
and/or structural edits) are decomposed to expose
each change site. Subtrees from non-deterministic
regions are similarly broken down, triggered by a
failure of the normal state matching test.
If a
conﬂict is encountered, the parser splits just as
in batch GLR parsing, and subtrees in the input
stream are fully decomposed until a deterministic
state is re-established (see the shifter routine in
Appendix A).
Shifting an unmodiﬁed, non-trivial subtree con-
denses a sequence of transitions by the correspond-
ing batch GLR parser. The portion of the abstract
parse dag reused when the incremental algorithm
shifts a non-trivial subtree reﬂect any splitting or
merging that would occur in the GSS of the batch
algorithm as it parsed the subtree’s terminal yield.
The correctness of skipping the intermediate steps is
guaranteed in deterministic states by the usual in-
cremental context checks, and in non-deterministic
states (which are treated as an equivalence class) by
the restriction to terminal lookaheads. The correct-
ness of incremental GLR parsing can then be estab-
lished by an induction over the input stream.
Our approach differs signiﬁcantly from the non-
deterministic PDA simulator of Ferro and Dion [4],
which uses the GSS itself as the persistent represen-
tation of the program. Their representation requires

more space than our parse dag, in part because un-
successful parses (used to overcome lookahead limi-
tations) must be retained for the sake of future state
comparisons. (In Figure 5, the portion of the GSS
constructed by Parser 2 must be kept, even though it
represents an unsuccessful search.) Their algorithm
also makes state comparisons and semantic attribu-
tion more expensive, since both must refer to a col-
lection of nodes.
As with deterministic parsing, IGLR parsing can
be extended to retain existing program structure
through node reuse [14, 19, 25].
Both ambiguous
and unambiguous reuse models are valid for abstract
parse dags, and both bottom-up and top-down reuse
mechanisms can be applied. (For on-the-ﬂy bottom-
up reuse, we advocate retaining a single, shared list
of reused nodes; maintaining separate lists when
multiple parsers are active imposes a performance
and complexity cost for minimal gain in the number
of reused nodes.)
3.4
Asymptotic Analysis
The IGLR parsing algorithm works for any context-
free grammar and, like GLR parsing, is exponen-
tial in the worst-case [9] but linear on actual pro-
gramming language grammars. To ensure incremen-
tal performance that improves on batch parsing, we
need to impose some additional restrictions on both
the grammar and the representation of the abstract
parse dag.
Incremental behavior requires that the abstract
parse dag support logarithmic access time to each
node. This is not the normal case: repetitive struc-
ture, such as sequences of statements or lists of dec-
larations, is typically expressed in grammars and
represented in trees in a left- or right-recursive man-
ner. These parse ‘trees’ are thus really linked lists,
with the concomitant performance implication: any
incremental algorithms degenerate to at best linear
behavior, and thus represent no asymptotic advan-
tage over their batch counterparts.
There are two types of operators in grammars
that create recursive structure: those that might
have semantic signiﬁcance, such as arithmetic op-
erators, and those that are truly associative, such
as the (possibly implicit) sequencing operators that
separate statements. The former do not represent
true performance problems because they are natu-
rally limited; for instance, we can assume that the
size of an expression in C is bounded by a constant in
practice. The latter type are problematic, since they
are usually quite lengthy in non-trivial programs.
To address this problem, we represent associative
operators in the abstract parse dag as balanced bi-
nary trees. An obvious way to indicate the freedom
to choose a balanced representation for associative
sequences is to describe the syntax of the language
using an extended context-free (regular right part)
grammar [12].
We thus use the grammar both to
specify the syntax of the language and to describe
declaratively the representation of the resulting ab-
stract parse dag. Productions in the grammar cor-
respond directly to nodes in the tree, while regu-
lar expressions denoting sequences have an inter-
nal representation chosen by the system—one that
is guaranteed to maintain logarithmic performance.
For purposes of analysis, we assume that any un-
bounded sequences are expressed in this fashion in
the grammar. (Note that changes to the grammar
are required—the parser generator cannot infer that
a given sequence is associative.)
In addition, we need to assume that no non-de-
terministic region spans a lengthy sequence, since
this would naturally require the entire sequence
to be reconstructed whenever any part of it was
changed. (Note that the elements of the sequence can
be parsed non-deterministically or even be ambigu-
ous, as is the case with C++.) Similarly, the interpre-
tation of a sequence’s yield cannot have more than a
bounded dependence on its surrounding context, so
that changes to adjacent material will not induce a
complete reconstruction of the sequence.
Given this assumption regarding the form of the
grammar and the representation of the abstract
parse dag, we can analyze the time performance of
the IGLR parser. In the typical case where the left
and right context of a subtree are unchanged, a state-
matching algorithm will shift that subtree in
O
()
time. In the event the context has changed, a valid
subtree containing
M nodes can be shifted in
O
(lg
M
)
steps by reconstructing its leading or trailing edge.
Reductions and the deterministic right context check
are often accomplished in
O
() time using the follow-
ing subtree; in the worst case the following termi-
nal symbol is located in
O
(lg
M
) steps. Locally non-
deterministic regions are reconstructed in their en-
tirety, but our assumption that the size of such re-
gions is effectively bounded (Section 2.1) implies a
constant bound on the time to parse them. The result
is a typical parsing time of
O
(t
+
s
lg
N
), for
t new ter-
minal symbols and
s modiﬁcation sites in a tree with
N nodes, and
O
(t
+
s(lg
N
)

) time in the worst case.
(Empirical results are discussed in Section 5.)
3.5
Correct and Optimal Sharing
Our approach treats the GSS as a transient data
structure of the parser, using it to construct the
abstract parse dag in the same way deterministic
parsers construct a concrete parse tree with the help
of a parse stack. However, the connection is more
complex than in the deterministic case. In this sec-
tion we discuss the removal of parsing artifacts from
the shared parse forest discovered by GLR methods
to produce the representation described in Section 2.
The parse forest produced by GLR parsing re-
sults in both over- and under-sharing, complicat-
ing (in some cases precluding) the application of ex-
isting methods for semantic attribution and similar
tools. GLR parsing as originally deﬁned [22] results
in under-sharing in the shared parse forest when iso-
morphic subtrees with the same yield are created
in different states (i.e., by different parsers) due to
left or right contextual restrictions.
 Rekers corrects
This is the same effect that causes incremental deterministic parsers
based on state-matching to fail to reuse subtrees as aggressively as
sentential-form parsers [25].

under-sharing in his batch GLR parser by merging
nodes that have identical yields [20]. Merging is per-
formed separately for both symbol and ‘rule’ (produc-
tion) nodes. The same approach can be applied in
our algorithm, since non-deterministic regions are
reconstructed atomically.
A different problem exhibited by GLR algorithms
is over-sharing.
A GLR parser does not distin-
guish non-determinism to acquire additional looka-
head information from its use in parsing ambigu-
ous phrases. In most cases, non-determinism for dy-
namic lookahead results in deterministic (and un-
shared) structure in the parse tree, since unsuccess-
ful parses eventually terminate. In the GSS, how-
ever, sharing needed to handle certain types of gram-
mars with
-productions results in sharing in the
parse tree even for unambiguous grammars [18]. We
consider this a ﬂaw; among other problems, it pro-
hibits semantic attributes or annotations from being
uniquely assigned to productions with a null yield,
since separate instances may not exist in the parse
tree.
(Rekers’ algorithm exacerbates this problem
by merging additional null-yield subtrees, violating
left-to-right ordering.) We correct this problem by
adding a post-pass that incrementally duplicates any
null-yield subtrees updated by the parser. Since a
unique maximal sharing of these subtrees does not
necessarily exist, this is the only approach that is
consistent, correct, and practical. Node reuse strate-
gies can be used to prevent unnecessary recreation of
these and other subtrees [25].
4
Resolving Ambiguity
The ultimate use of the abstract parse dag is to en-
able disambiguation once the needed information is
available. This ‘ﬁltering’ of alternatives can be static
(decided at language speciﬁcation time) or dynamic
(decided at program analysis time). Dynamic ﬁlter-
ing can involve both syntactic and semantic informa-
tion. The abstract parse dag and incremental GLR
parser together provide a uniform and ﬂexible frame-
work for implementing ambiguity resolution at any
point in the analysis process.
4.1
Syntactic Disambiguation
Static syntactic ﬁlters, in conjunction with ambigu-
ous grammars, are used frequently in compiler con-
struction.
Examples include the operator prece-
dence and associativity speciﬁcations in yacc and
bison [1] as well as techniques associated with a
particular parse table construction algorithm, such
as “prefer shifting”. Such methods can be applied at
language speciﬁcation time by selectively removing
conﬂicts from the parse table, and therefore do not
result in non-deterministic parsing or multiple rep-
resentations. Since state-matching incrementalizes
transitions in the pushdown automaton, any disam-
biguation statically encoded in the parse table is sup-
ported by the IGLR parser.
When the selection of a preferred interpretation
cannot be determined a priori based on the left con-
text and the implicit (‘builtin’) lookahead, a dynamic
ﬁlter is required. For example, the syntactic ambigu-
ity in C++ expressed as “prefer a declaration to an ex-
pression” requires a dynamic ﬁlter, since competing
reductions cannot be delayed until sufﬁcient looka-
head has been accumulated [3]. The abstract parse
dag allows ambiguities of this form to be encoded
using multiple interpretations; an incremental post-
pass can then select the preferred structure by di-
rectly applying rules such as the one above.
 Syn-
tactic disambiguation of this form can also take place
on-the-ﬂy, provided it occurs only in a deterministic
state to avoid contaminating the dynamic lookahead
computation. Unlike Ferro and Dion [4], we do not
retain interpretations eliminated by syntactic ﬁlters.
In general, disambiguation speciﬁcations [6, 11]
can be compiled into a combination of static and dy-
namic ﬁlters.
Encoding as much ﬁltering as pos-
sible at language speciﬁcation time decreases both
the size of the representation and the analysis time.
(This contrasts with existing batch GLR environ-
ments, which perform all syntactic ﬁltering dynam-
ically [20, 22], and thus require quadratic space for
each expression, in contrast to the negligible in-
creases we report in Section 2.1.)
4.2
Semantic Disambiguation
Filters for which the selection criteria are not con-
text-free are referred to as ‘semantic’ ﬁlters. They
may be applied in an ad hoc manner or as part of a
formal semantic attribution process (using attribute
grammars or other approaches).
Semantic ﬁlters
are always dynamic; they are typically applied only
after incremental parsing and any syntactic ﬁlter-
ing passes have completed. This organization pre-
serves the familiar pass-oriented framework of batch
compilation even though the analysis techniques are
incremental—it thus avoids the feedback that char-
acterizes the solution to the ‘typedef problem’ in ex-
isting batch systems. While a complete discussion of
incremental semantic analysis is beyond the scope
of this paper, in this section we brieﬂy outline the
sequence of events by which incremental semantic
analysis can resolve our running example.
Figure 8 illustrates the sequence of events. Af-
ter context-free analysis is complete, the ﬁrst stage
of semantic analysis is applied to process typedef
declarations. Type names introduced by such decla-
rations are gathered into a binding contour, which is
then propagated throughout the scope. (This infor-
mation will be inherited by both children of a sym-
bol node, reaching each identiﬁer in an ambiguous
region twice.) In a correct program, the binding con-
tour’s contents uniquely determine the namespace
for each identiﬁer.
With identiﬁer namespaces decided, disambigua-
tion per se can take place: ‘parsing’ is completed by
propagating the namespace decision throughout the
ambiguous region. Boolean semantic attributes in-
dicate nodes ﬁltered out of the parse dag in the un-
wanted interpretation. Since all syntactic and sem-
Contrast this with non-GLR approaches, such as spawning a separate,
hand-coded parser for potentially ambiguous regions.

decl
(
stmt
)
"b"
ident
Typedefs
a: int
...
;
"a"
ident
block
block
decl
"a"
ident
int
typedef
type_decl
item
a. Processing type deﬁnitions.
)
decl
decl
block
stmt
Typedefs
a: int
...
;
(
"b"
ident
"a"
ident
block
item
b. Propagating typedef bindings.
)
;
(
"b"
decl
ident
"a"
ident
block
Typedefs
a: int
...
decl
block
stmt
item
c. Filtering semantic ambiguities.
"b"
(
ident
;
ident
Typedefs
a: int
)
block
decl
"a"
Decls
b: int
...
...
block
stmt
item
decl
d. Remaining semantic passes.
Figure 8: Illustration of semantic disambiguation. This shows our running example (using C++, although the situation is similar in
both C and Fortran) during the semantic analysis passes. In (a) the basic context-free analysis has been completed, and the ﬁrst stage of
semantic analysis now resolves typedef deﬁnitions. In (b) this binding information is propagated to the ambiguous regions, allowing the
selection of the appropriate namespace for each identiﬁer. In (c) disambiguation per se occurs, as the unwanted interpretation is ﬁltered
out (it is retained in case future edits reverse the decision). In (d) semantic analysis continues, using the embedded tree discovered by
stages a–c. (Note: The right-hand side of production labels are omitted.)
antic ambiguities have now been resolved, each sym-
bol node can be logically identiﬁed with its single re-
maining child in subsequent passes, allowing tools to
treat the result as a normal parse tree.

The order of the passes is the same for both batch
and incremental scenarios. In the incremental case,
each stage inspects or updates only those portions of
the program that have changed or could possibly be
affected by preceding changes [16]. An interesting
case occurs when a typedef declaration is removed:
Binding information stored in semantic attributes
allows the former uses of the declaration to be efﬁ-
ciently located. At each use site, the interpretation
of the ambiguous region will change from a variable
declaration to a function call as the namespace of the
region’s initial identiﬁer is altered. Note that the use
sites themselves require no action from the parser;
other attributes of the reinterpreted regions are re-
evaluated as semantic analysis progresses.
Unlike syntactic disambiguation, semantic disambiguation requires
that the unwanted interpretations be retained in the abstract parse dag.
Semantic ﬁltering uses non-local information (such as declarations in en-
closing scopes) that can change and thus require a different resolution with-
out a change to the local structure.
4.3
Program Errors
When the program is correct with respect to the lan-
guage description (and the language as a whole is un-
ambiguous) a single structural representation will
eventually be discovered. In the presence of sem-
antic errors, such as missing, malformed, or incon-
sistent declarations, it may not be possible to de-
termine a single interpretation of the entire struc-
ture.
In such cases the abstract parse dag main-
tains multiple interpretations persistently; future
edit/analysis cycles may eventually correct the er-
rors and allow the resolution to succeed. These re-
gions are re-evaluated by the parser only when they
are modiﬁed and by semantic analysis only when
they require re-interpretation.
Maintaining every potential interpretation in the
presence of an error provides tools in the environ-
ment with all relevant information. While the pres-
ence of persistent ambiguities may preclude some
services, such as code generation, analyses not de-
pendent on the missing information and services
that do not require complete resolution (such as pre-
sentation) can continue to operate using the unre-

solved parse dag.
Errors in the context-free syntax may also oc-
cur and are detected in the usual fashion: when no
parser can successfully shift the (terminal) looka-
head symbol. Syntactic error recovery can be sup-
ported in the same fashion that we have adopted
for deterministic parsing: a history-sensitive, non-
correcting strategy that reports deviations from cor-
rect program components by integrating only those
user modiﬁcations that result in at least one valid
parse tree. Any modiﬁcations remaining are ﬂagged
as unincorporated material [27]. This approach is
automated, language-independent, and incremen-
tal.
The primary change needed to support IGLR
parsing is an extension of the isolation boundary
test to ensure that each non-deterministic region is
treated as an atomic unit: partial update incorpora-
tion within such a region is not permitted. (This has
no practical effect on the efﬁcacy of the recovery, due
to the small size of these regions in actual programs.)
5
Implementation and
Empirical Performance
The concepts described in this paper have been
implemented as part of the Ensemble incremen-
tal software development environment being proto-
typed at UC Berkeley. Ensemble supports language
deﬁnition through the off-line compilation of high-
level speciﬁcations, dynamically loading the com-
piled language analysis tools into a running environ-
ment. Existing language deﬁnitions include Java,
Modula-2, Fortran, a subset of Lisp, and C (with lim-
ited preprocessor support).
The IGLR parser has been implemented in this
system as an alternative to the sentential-form pars-
er used for deterministic grammars [25]. The IGLR
implementation, which includes the parse table in-
terface but not error recovery code, occupies less
than 2000 lines of C++ code, including all tracing
and assertion checking. The actual implementation
corresponds closely to the algorithm given in Ap-
pendix A. Support for abstract parse dags required
very little change to Ensemble’s low-level represen-
tation, which is based on the self-versioning docu-
ment model [26].
Parse table information is pro-
duced using a modiﬁed version of bison that explic-
itly records all conﬂicts in the grammar except for
those arising from the expansion of the associative
sequence notation.
Despite the slightly less efﬁcient stack represen-
tation used for GLR parsing relative to determin-
istic parsing, the IGLR parser performs an initial
(‘batch’ ) parse nearly as fast as its deterministic
counterpart. C,
	 Java, and Modula-2 programs were
parsed with both parsers, and yielded an average
of 12% overhead due to parsing per se for the de-
terministic parser, compared with 15% for the IGLR
parser.
Most of the remaining time was spent in
constructing the nodes. In incremental tests (self-
cancelling modiﬁcations to individual tokens, pars-
	For this comparison, the ‘typedef’ ambiguity was removed artiﬁcially.
ing after each such change) the difference in running
times for the two parsers was undetectable.
Compared to sentential-form parsing for deter-
ministic grammars, the space consumption of the ab-
stract parse dag is approximately 5% higher, due
to the need to record explicit states in the nodes.
The difference becomes negligible when semantic
attributes, presentation data structures, and other
per-node storage is also considered.
The restriction that each non-deterministically
parsed region be reconstructed in its entirety when-
ever it contains at least one edit site imposes lit-
tle overhead in practice: since none of these regions
spanned more than a few nodes in any of our sam-
ple programs, the additional reconstruction time was
well under 1%, independent of the program, source
ﬁle, or location of the ambiguous region within the
ﬁle.
6
Extensions and Future Work
Techniques for expressing both syntactic and seman-
tic ﬁltering in a uniform language would both sim-
plify the language description process and allow op-
timized performance by applying resolutions at the
earliest possible stage. Visser
uses priorities and
tree patterns to produce static ﬁlters [23], but fur-
ther work is needed.
An integrated model of semantic attribution and
dynamic (semantic) ﬁlters remains an open problem.
It requires extending scheduling algorithms to dags,
balancing the restrictions required for efﬁcient static
scheduling with sufﬁcient expressive power to model
disambiguation methods that arise in practice. This
would improve language speciﬁcations and enable
veriﬁcation of the combined description.
Incremental, non-deterministic parsing may also
ﬁnd application in rewrite systems and in the itera-
tive analysis of natural language documents.
7
Conclusion
This paper provides a mechanism for applying the
open, pass-oriented framework of batch analysis
tools to incremental environments. A new IR, the ab-
stract parse dag, is introduced to model ambiguity
in programming language analysis. Circular anal-
ysis dependencies as they exist in C, C++, Fortran,
and other common languages are eliminated by the
ability to apply disambiguation ﬁlters at any point in
the analysis process. Arbitrary CFGs may be used
to describe the form of the parse dag, as well as to
produce fast incremental parsers based on our IGLR
algorithm. Optimal and correct subtree and context
sharing in the abstract parse dag are obtained by re-
moving parsing artifacts from the shared parse for-
est. Empirical measurements demonstrate the space
efﬁciency of our representation and the time efﬁ-
ciency of our reconstruction methods, both of which
exploit an underlying language property: localized
non-determinism.

8
Acknowledgments
Special thanks to William Maddox for discussing
parsing theory and semantic analysis techniques
and to John Boyland for his tireless LATEX assistance
and makebib tool.
References
[1] A. V. Aho, S. C. Johnson, and J. D. Ullman. Deterministic
parsing of ambiguous grammars. Commun. ACM, 18(8):441–
452, Aug. 1975.
[2] J. Earley. An efﬁcient context-free parsing algorithm. Com-
mun. ACM, 13(2):94–102, Feb. 1970.
[3] Margaret A. Ellis and Bjarne Stroustrup. The Annotated C++
Reference Manual. Addison-Wesley, 1990. Sect. 6.8, 8.1.1.
[4] M. V. Ferro and B. A. Dion. Efﬁcient incremental parsing for
context-free languages. In Proc. 1994 IEEE Intl. Conf. Comp.
Lang., pages 241–252. IEEE Computer Society Press, May
1994.
[5] Robert Giegerich.
Considerate code selection.
In Robert
Giegerich and Susan L. Graham, editors, Code Generation
— Concepts, Tools, Techniques., Workshops in Computing,
pages 51–65, Berlin, May 1991. Springer-Verlag.
[6] J. Heering, P. R. H. Hendriks, P. Klint, and J. Rekers. The
syntax deﬁnition formalism SDF — Reference Manual, Dec.
1992.
[7] Paul Hudak et al. Haskell report. SIGPLAN Not., 27(5):R,
May 1992.
[8] Fahimeh Jalili and Jean H. Gallier.
Building friendly
parsers. In 9th ACM Symp. Principles of Prog. Lang., pages
196–206, New York, 1982. ACM Press.
[9] Mark Johnson. The computational complexity of GLR pars-
ing.
In Masaru Tomita, editor, Generalized LR Parsing,
pages 35–42. Kluwer Academic Publishers, 1991.
[10] Neil D. Jones and Michael Madsen. Attribute-inﬂuenced LR
parsing. In U. D. Jones, editor, Semantics-Directed Compiler
Generation, number 94 in LNCS, pages 393–407, Berlin,
1980. Springer-Verlag.
[11] Paul Klint and Eelco Visser. Using ﬁlters for the disambigu-
ation of context-free grammars. In Proc. ASMICS Workshop
on Parsing Theory, Milan, Italy, 1994.
[12] Wilf R. LaLonde.
Regular right part grammars and their
parsers. Commun. ACM, 20(10):731–740, 1977.
[13] Marc Lankhorst. An empirical comparison of generalized LR
tables.
In R. Heemels, A. Nijholt, and K. Sikkel, editors,
Tomita’s Algorithm: Extensions and Applications (TWLT1),
number 91–68 of Memoranda Informatica in Twente Work-
shops on Language Technology, pages 87–93. Universeit
Twente, 1991.
[14] J. M. Larchevˆeque.
Optimal incremental parsing.
ACM
Trans. Program. Lang. Syst., 17(1):1–15, 1995.
[15] Maryellen C. MacDonald, Marcel Adam Just, and Patricia A.
Carpenter. Working memory constraints on the processing of
syntactic ambiguity. Cog. Psych., 24(1):56–98, 1992.
[16] William Maddox.
Incremental Static Semantic Analysis.
Ph.D. dissertation, University of California, Berkeley, 1997.
[17] Akira Miyake, Marcel Adam Just, and Patricia A. Carpen-
ter. Working memory constraints on the resolution of lexical
ambiguity: Maintaining multiple interpretations in neutral
contexts. J. Memory and Lang., 33(2):175–202, Apr. 1994.
[18] R. Nozohoor-Farshi.
GLR parsing for
-grammars.
In
Masaru Tomita, editor, Generalized LR Parsing, pages 61–
75. Kluwer Academic Publishers, 1991.
[19] Luigi Petrone.
Reusing batch parsers as incremental
parsers. In Proc. 15th Conf. Foundations Softw. Tech. and
Theor. Comput. Sci., number 1026 in LNCS, pages 111–123,
Berlin, Dec. 1995. Springer-Verlag.
[20] Jan Rekers. Parser Generation for Interactive Environments.
Ph.D. dissertation, University of Amsterdam, 1992.
[21] Masataka Sassa, Harushi Ishizuka, and Ikuo Nakata. Rie, a
compiler generator based on a one-pass-type attribute gram-
mar. Software—Practice & Experience, 25(3):229–250, Mar.
1995.
[22] Masaru Tomita.
Efﬁcient Parsing for Natural Languages.
Kluwer Academic Publishers, 1985.
[23] Eelco Visser. A case study in optimizing parsing schemata
by disambiguation ﬁlters. Technical Report P9507, Program-
ming Research Group, University of Amsterdam, Jul. 1995.
[24] Eelco Visser. Scannerless generalized-LR parsing, 1997. In
preparation.
[25] Tim A. Wagner and Susan L. Graham. Efﬁcient and ﬂexible
incremental parsing, 1996. Submitted to ACM Trans. Pro-
gram. Lang. Syst.
[26] Tim A. Wagner and Susan L. Graham.
Efﬁcient self-
versioning documents. In CompCon ’97, pages 62–67. IEEE
Computer Society Press, Feb. 1997.
[27] Tim A. Wagner and Susan L. Graham. Isolating errors—a
history-based approach, 1997. In preparation.
[28] David A. Watt. Rule splitting and attribute-directed pars-
ing. In U. D. Jones, editor, Semantics-Directed Compiler Gen-
eration, number 94 in LNCS, pages 363–392, Berlin, 1980.
Springer-Verlag.
Appendix A: IGLR Parsing Algorithm
The non-deterministic component of the IGLR
parser is based on Rekers’ batch parser [20].
class NODE
Normal parse dag node
int type;
production or symbol #
int state;
deterministic parse state or noState
setof NODE kids; rhs of a production; interpretations of a symbol
NODE (int type, int state, setof NODE kids) {:
:
:}
subclass SYMBOL of NODE
Symbol (choice) node
SYMBOL (NODE node) {
type = symbol(node!type); rule’s left-hand side
state = noState;
multistate by deﬁnition
kids = {node};
ﬁrst interpretation
}
add_choice (NODE node) {kids = kids
[ node;}
class GSS_NODE
Node in the GSS
int state;
state of constructing parser
setof LINK links; links to earlier nodes
GSS_NODE (int state, LINK link) {:
:
:}
add_link (LINK link) {links = links
[ link;}
class LINK
Edge in the GSS
GSS_NODE head; preceding node in the GSS
NODE node;
parse dag node labeling this edge
LINK (GSS_NODE head, NODE node) {:
:
:}
bool multipleStates;
Global variables
NODE shiftLa; lookahead symbol (subtree)
NODE redLa;
lookahead for reducing
GSS_NODE acceptingParser;
setof GSS_NODE activeParsers, forActor, forShifter;
setof NODE nodes;
production node merge table
setof SYMBOL symbolnodes; symbol node merge table

inc_parse (NODE root) {
Main routine
process_modifications_to_parse_dag(root);
redLa = shiftLa = pop_lookahead(root!bos);
GSS_NODE gss = new GSS_NODE(0,
;);
activeParsers = {gss};
acceptingParser =
;;
multipleStates = false;
while (acceptingParser ==
;) parse_next_symbol();
if (shiftLa
= eos) recover();
root!kids[1] = first(acceptParser!links)!node;
unshare_epsilon_structure(root);
delete gss;
}
parse_next_symbol () {
reduce
shift sequence
forActor = activeParsers;
forShifter = nodes = symbolnodes =
;;
while (forActor
=
;) do {
remove a parser p from forActor;
actor(p); Process all reductions,
}
shifter();
then shift.
redLa = shiftLa = pop_lookahead(shiftLa);
}
actor (GSS_NODE p) {
Transition one parser
while (redLa is an invalid table index)
redLa = left_breakdown(redLa);
if (jparse_table[p!state, redLa]j > 1)
multipleStates = true;
action
 parse_table[p!state, redLa] do
switch (action) {
case ACCEPT: if (redLa == eos) acceptingParser = p;
else recover();
break;
case REDUCE r: do_reductions(p, r); break;
case SHIFT s: forShifter = forShifter
[ <p,s>;
break;
case ERROR: if (activeParsers ==
;)
recover(); Recover from a parse error.
}
}
shifter () {
Shift all parsers
if (is_terminal(shiftLa) &&
shiftLa!has_changes(lastParsedVersion))
relex(shiftLa); Invoke lexer and reset lookaheads
activeParsers =
;;
multipleStates =
jfor_shifterj > 1;
while (!is_term(shiftLa) && (multipleStates ||
forShifter!state
= shiftLa!state))
shiftLa = left_breakdown(shiftLa);
<q,s>
 forShifter do
if (	p
 activeParsers with p!state == q)
p!add_link(new LINK(q, shiftLa));
else activeParsers = activeParser
[
new GSS_NODE(q, new LINK(s, shiftLa))
}
do_reductions (GSS_NODE p, int rule) {
Find all paths
GSS_NODE q;
q such that a path of length arity(rule)
from p to q exists do {
kids = the tree nodes of the links forming the path
from q to p;
reducer(q, GOTO(q!state, symbol(rule)), rule, kids);
}
}
Path-restricted version of above function
do_limited_reductions (GSS_NODE p, int rule, LINK link) {
q such that a path of length arity(rule)
from p to q through link exists do {
kids = the tree nodes of the links forming the path
from q to p;
reducer(q, GOTO(q!state, symbol(rule)), rule, kids);
}
}
reducer (GSS_NODE q, int state,
Perform a
int rule, setof NODE kids) {
single reduction
NODE node = get_node(rule, kids, q!state);
if (	p
 activeParsers with p!state == state)
if there already exists a direct link from p to q
add_choice(link!head, node);
else {
NODE n = get_symbolnode(node);
p!add_link(new LINK(q, n));
m in activeParsers\forActor do
(reduce rule)
 parse_table[m!state, redLa] do
do_limited_reductions(m, rule, link);
}
else {
GSS_NODE p = new GSS_NODE(state,
new LINK(q, get_symbolnode(node)));
activeParsers = activeParsers
[ p;
forActor = forActor
[ p;
}
}
<int,int> cover (setof NODE kids) {
Get offset range
if (kids ==
;)
return <offset(shiftLa),offset(shiftLa)>;
else return <offset(first(kids)),offset(last(kids))>;
}
NODE get_node (int rule, setof NODE kids,
Create or reuse
int precedingState) {
a ‘production’ node
if (	n
 nodes with n!type == rule && n!kids == kids)
return n;
if (multipleStates)
NODE n = new NODE(rule, noState, kids);
else NODE n = new NODE(rule, precedingState, kids);
nodes = nodes
[ n;
return n;
}
add_choice (NODE symnode?, NODE node) {
Instantiate
if (symnode? is a symbol node)
symbol nodes lazily
symnode!add_choice(node);
else if (symnode? != node) {
replace symnode? with sym
 symbolnodes such that
first(sym!kids) == symnode?;
sym!add_choice(node);
}
}
NODE get_symbolnode (NODE node) {
Use normal nodes
if (	sym
 symbolnodes with
whenever possible
sym!symbol == symbol(node!type) &&
cover(first(s!kids)!kids) == cover(node!kids))
sym!add_choice(node);
else SYMBOL sym = new SYMBOL(node);
symbolnodes = symbolnodes
[ sym;
if (jsym!kidsj == 1) return node;
proxy case
else return sym;
real case
}
The following two routines update the right (input) stack of the
incremental parser. One level of structure is removed per invoca-
tion of left_breakdown. pop_lookahead advances the looka-
head to the next subtree for consideration by traversing the pre-
vious structure of the tree. The previously-parsed version of the
program is denoted by lastParsedVersion.
NODE left_breakdown (NODE n) {
if (n!arity > 0) {
n = n!first_child(previousVersion);
if (n!has_changes(lastParsedVersion))
return left_breakdown(n);
} else return pop_lookahead(n);
}

NODE pop_lookahead (NODE n) {
while (n!right_sibling(previousVersion) ==
;)
n = n!parent(previousVersion);
n = n!right_sibling(previousVersion);
if (n!has_changes(lastParsedVersion))
return left_breakdown(n);
return n;
}
The function process_modifications_to_parse_dag (called
by inc_parse) is used to invalidate reductions containing a modi-
ﬁed terminal in their yield or implicit (built-in) lookahead. (Struc-
tural modiﬁcations can also be accommodated.)
Let
T denote the set of modiﬁed terminals (textual edit sites).
Add to
T any terminal having lexical lookahead in some
t

T.
Mark as changed any nonterminal
N for which yield(N)
[ the ter-
minal following yield(N) contains any
t

T.
Appendix B: Sample C++ Trace
In this example we trace the parser’s actions in con-
structing the dual interpretations of the ‘typedef’
problem in C++, using a simpliﬁed grammar. Con-
sider the input stream as it appears in (1), and sup-
pose the semicolon has been deleted and then re-
inserted. The region to the left of the semicolon was
an ambiguous item; the edit to the semicolon causes
the parser to discard the non-deterministic structure
and read id(id) as terminal symbols.
Distinguishing between a normal identiﬁer and a
type-name identiﬁer is not context-free; the ambigu-
ity manifests as a reduce/reduce conﬂict in (2), caus-
ing the parser to split. Each of the two parsers now
active will create one of the two possible interpre-
tations. A subsequent incremental semantic analy-
sis pass will perform the scope resolution and name
binding needed to distinguish the desired interpreta-
tion, based on earlier declarations. In a correct pro-
gram, either a typedef or a function declaration will
have established the correct namespace for the lead-
ing id. (The situation would be similar in C, assum-
ing that further input did not yield a purely syntactic
resolution.)
While multiple parsers are active, only terminal
symbols can be read by the parser. (In this exam-
ple the breakdown of the ambiguous subtree has al-
ready accomplished this.) The breadth-ﬁrst nature
of GLR parsing means that each terminal symbol is
shifted in tandem by all active parsers (3, 4, 7, 11).
In (13) context sharing occurs as the two parsers
merge into a single parser. The item node shown
on top of the stack is a symbol node;
0 its two chil-
dren represent the two interpretations of its termi-
nal yield. Now that the state is once again determin-
istic, the parser returns to shifting entire subtrees.
0Not shown is its lazy instantiation. The ﬁrst item production serves as
a proxy for its symbol node; the attempt to add the second item production
as an alterate interpretation forces the installation of a real symbol node.
The real symbol node replaces the proxy, which becomes its ﬁrst child. The
second item production becomes the second child.
( id ) ; 
R: func_id->id
R: type_id->id
( id ) ; 
id
type_id ( decl_id
func_id ( arglist
) ; 
S: )
1
2
3
4
5
6
7
8
9
10
11
12
13
id ( id ) ; 
func_id ( arg
) ; 
R: arglist->arg
type_id ( decl_id
type_id ( id
func_id ( id
) ; 
R: decl_id->id
R: arg->id
S: id
type_id (
func_id (
id ) ; 
func_id
S: id
decl
funcall
; 
R: expr->funcall
decl
expr
; 
R: stmt->expr
type_id ( decl_id )
func_id ( arglist )
; 
item
decl
stmt
S: ;
; 
decl ;
stmt ;
R: item->stmt ;
R: item->decl ;
S:  
item->stmt ;
item->decl ;
R: funcall->func_id(arglist)
R: decl->type_id(decl_id)
S: (
type_id