"""Hand-written study content for the seeded courses (SRS 7.3).

Each course maps topic -> lists of questions and flashcards. Multiple-choice items are
(text, [options], correct_index, explanation). Short-answer items are
(text, model_answer, [accepted keywords], explanation). True/false items are derived from
the multiple-choice items in generate_seed.py.
"""

CONTENT = {
    "ICT 2201": {
        "Relational model": {
            "mcq": [
                ("In the relational model, a row of a table is formally called a:", ["Tuple", "Attribute", "Domain", "Schema"], 0,
                 "A relation is a set of tuples; each tuple is one row."),
                ("Which key uniquely identifies each row and cannot be NULL?", ["Foreign key", "Primary key", "Candidate key that allows NULL", "Composite attribute"], 1,
                 "Entity integrity requires the primary key to be unique and never NULL."),
                ("A foreign key enforces which kind of integrity?", ["Entity integrity", "Domain integrity", "Referential integrity", "User-defined integrity"], 2,
                 "A foreign key must match a primary key value in the referenced table or be NULL."),
                ("The set of allowed values for an attribute is its:", ["Degree", "Cardinality", "Domain", "Tuple"], 2,
                 "The domain defines the type and range of permitted values."),
                ("The number of attributes in a relation is called its:", ["Cardinality", "Degree", "Arity of keys", "Extension"], 1,
                 "Degree counts columns; cardinality counts rows."),
            ],
            "short": [
                ("Name the key that references the primary key of another table.", "Foreign key", ["foreign"],
                 "A foreign key links a row to a row in another relation."),
            ],
            "cards": [
                ("Candidate key", "A minimal set of attributes that uniquely identifies a tuple; the primary key is chosen from these."),
                ("Cardinality of a relation", "The number of tuples (rows) it contains."),
                ("Referential integrity", "Every foreign key value must match an existing primary key value or be NULL."),
            ],
        },
        "SQL": {
            "mcq": [
                ("Which SQL clause filters groups after aggregation?", ["WHERE", "HAVING", "ORDER BY", "GROUP BY"], 1,
                 "WHERE filters rows before grouping; HAVING filters the grouped results."),
                ("Which statement removes all rows but keeps the table structure, and cannot be rolled back in most systems?", ["DROP TABLE", "DELETE FROM", "TRUNCATE TABLE", "ALTER TABLE"], 2,
                 "TRUNCATE deallocates data pages quickly and keeps the table definition."),
                ("A LEFT JOIN returns:", ["Only matching rows", "All rows from the left table plus matches from the right", "All rows from both tables", "Only non-matching rows"], 1,
                 "Unmatched left rows appear with NULLs in the right table's columns."),
                ("Which aggregate ignores NULL values?", ["COUNT(*)", "COUNT(column)", "Both", "Neither"], 1,
                 "COUNT(*) counts rows; COUNT(column) counts non-NULL values in that column."),
                ("Which keyword removes duplicate rows from a SELECT result?", ["UNIQUE", "DISTINCT", "DIFFERENT", "SINGLE"], 1,
                 "SELECT DISTINCT returns each distinct row once."),
                ("Which SQL command category does GRANT belong to?", ["DDL", "DML", "DCL", "TCL"], 2,
                 "GRANT and REVOKE are Data Control Language."),
            ],
            "short": [
                ("Which SQL clause is used to sort the result set?", "ORDER BY", ["order by"],
                 "ORDER BY sorts ascending by default; add DESC for descending."),
                ("Which SQL clause combines rows that share values so aggregates can be computed per group?", "GROUP BY", ["group by"],
                 "GROUP BY collapses rows into groups for COUNT, SUM, AVG and so on."),
            ],
            "cards": [
                ("WHERE vs HAVING", "WHERE filters rows before grouping; HAVING filters groups after aggregation."),
                ("INNER JOIN", "Returns only rows with matching values in both tables."),
                ("DDL examples", "CREATE, ALTER, DROP, TRUNCATE."),
                ("DML examples", "SELECT, INSERT, UPDATE, DELETE."),
            ],
        },
        "Normalisation": {
            "mcq": [
                ("A relation is in 1NF when:", ["It has no partial dependencies", "All attribute values are atomic", "It has no transitive dependencies", "Every determinant is a candidate key"], 1,
                 "First normal form forbids repeating groups and multi-valued attributes."),
                ("2NF removes which kind of dependency?", ["Transitive", "Partial", "Multivalued", "Join"], 1,
                 "In 2NF no non-key attribute depends on only part of a composite key."),
                ("3NF removes which kind of dependency?", ["Partial", "Transitive", "Trivial", "Functional"], 1,
                 "In 3NF no non-key attribute depends on another non-key attribute."),
                ("BCNF requires that every determinant is a:", ["Foreign key", "Non-key attribute", "Candidate key", "Composite key"], 2,
                 "BCNF is a stricter form of 3NF."),
                ("Which anomaly occurs when deleting a row unintentionally removes other facts?", ["Insertion anomaly", "Update anomaly", "Deletion anomaly", "Read anomaly"], 2,
                 "Normalisation splits relations so that deleting one fact does not lose another."),
            ],
            "short": [
                ("What is the name for a dependency where A -> B and B -> C, so A -> C?", "Transitive dependency", ["transitive"],
                 "Transitive dependencies are removed in 3NF."),
            ],
            "cards": [
                ("Functional dependency", "A -> B means each value of A determines exactly one value of B."),
                ("Partial dependency", "A non-key attribute depends on part of a composite primary key. Removed in 2NF."),
                ("Update anomaly", "The same fact stored in several rows must be changed in all of them, or data becomes inconsistent."),
            ],
        },
        "ER modelling": {
            "mcq": [
                ("In an ER diagram, a weak entity is one that:", ["Has no attributes", "Cannot be identified without its owner entity", "Has only one relationship", "Is optional"], 1,
                 "A weak entity uses a partial key plus the owner's key."),
                ("A many-to-many relationship is implemented in a relational schema by:", ["A foreign key on one side", "Merging both tables", "A junction (associative) table", "A view"], 2,
                 "The junction table holds foreign keys to both entities."),
                ("An attribute that can be calculated from other attributes is:", ["Composite", "Derived", "Multivalued", "Key"], 1,
                 "For example, age derived from date of birth."),
                ("Cardinality in an ER relationship describes:", ["The number of attributes", "How many instances of one entity relate to another", "The data type", "The primary key size"], 1,
                 "Examples: one-to-one, one-to-many, many-to-many."),
            ],
            "short": [
                ("What type of table resolves a many-to-many relationship?", "Junction table", ["junction", "associative", "bridge", "link"],
                 "Also called an associative or bridge table."),
            ],
            "cards": [
                ("Weak entity", "An entity whose key depends on a related (owner) entity."),
                ("Multivalued attribute", "An attribute that can hold several values, such as phone numbers; mapped to its own table."),
            ],
        },
        "Transactions": {
            "mcq": [
                ("The A in ACID stands for:", ["Availability", "Atomicity", "Authorisation", "Accuracy"], 1,
                 "Atomicity: a transaction completes fully or not at all."),
                ("Which property ensures committed data survives a crash?", ["Consistency", "Isolation", "Durability", "Atomicity"], 2,
                 "Durability is provided by logging and recovery."),
                ("A dirty read happens when a transaction reads data that is:", ["Committed", "Uncommitted by another transaction", "Indexed", "Locked exclusively by itself"], 1,
                 "Read Uncommitted isolation allows dirty reads."),
                ("Two transactions each waiting for a lock the other holds is called:", ["Starvation", "Deadlock", "Livelock", "Rollback"], 1,
                 "DBMSs detect deadlocks and abort one transaction."),
            ],
            "short": [
                ("Which SQL command makes a transaction's changes permanent?", "COMMIT", ["commit"],
                 "ROLLBACK undoes them instead."),
            ],
            "cards": [
                ("ACID", "Atomicity, Consistency, Isolation, Durability."),
                ("Two-phase locking", "A growing phase acquires locks, a shrinking phase releases them; guarantees serialisability."),
                ("Rollback", "Undo all changes made by the current transaction."),
            ],
        },
    },
    "ICT 2205": {
        "Complexity": {
            "mcq": [
                ("The time complexity of binary search on a sorted array is:", ["O(n)", "O(log n)", "O(n log n)", "O(1)"], 1,
                 "Each step halves the search interval."),
                ("Which grows fastest as n increases?", ["O(n^2)", "O(n log n)", "O(2^n)", "O(n^3)"], 2,
                 "Exponential growth outpaces any polynomial."),
                ("Big-O notation describes an algorithm's:", ["Exact running time", "Upper bound on growth rate", "Memory address", "Lower bound only"], 1,
                 "Big-O is an asymptotic upper bound."),
                ("Accessing an array element by index is:", ["O(1)", "O(log n)", "O(n)", "O(n^2)"], 0,
                 "Address = base + index x element size."),
            ],
            "short": [
                ("What is the worst-case time complexity of linear search, in Big-O?", "O(n)", ["o(n)", "linear"],
                 "Every element may need to be checked."),
            ],
            "cards": [
                ("O(n log n)", "Typical of efficient comparison sorts such as merge sort and heap sort."),
                ("Space complexity", "How much extra memory an algorithm needs as input size grows."),
                ("Amortised analysis", "Average cost per operation over a sequence, e.g. dynamic array append is O(1) amortised."),
            ],
        },
        "Linked lists": {
            "mcq": [
                ("Inserting at the head of a singly linked list takes:", ["O(1)", "O(log n)", "O(n)", "O(n^2)"], 0,
                 "Only the head pointer and the new node's next pointer change."),
                ("Each node of a doubly linked list stores:", ["Data only", "Data and next pointer", "Data, next and previous pointers", "Two data fields"], 2,
                 "The previous pointer allows backward traversal."),
                ("Finding the k-th element of a linked list takes:", ["O(1)", "O(k)", "O(log k)", "O(k^2)"], 1,
                 "Lists have no random access; you walk k nodes."),
                ("A circular linked list's last node points to:", ["NULL", "Itself", "The first node", "The middle node"], 2,
                 "This makes the list a cycle."),
            ],
            "short": [
                ("What value does the next pointer of the last node of a singly linked list hold?", "NULL", ["null", "none", "nil"],
                 "NULL marks the end of the list."),
            ],
            "cards": [
                ("Linked list vs array", "Lists give O(1) insert at known position but O(n) access; arrays give O(1) access but costly inserts."),
                ("Sentinel node", "A dummy node that simplifies edge cases at the head or tail."),
            ],
        },
        "Stacks and queues": {
            "mcq": [
                ("A stack follows which order?", ["FIFO", "LIFO", "Priority", "Random"], 1,
                 "Last In, First Out."),
                ("Which structure is used to evaluate postfix expressions?", ["Queue", "Stack", "Heap", "Graph"], 1,
                 "Operands are pushed; operators pop two operands."),
                ("Breadth-first search uses a:", ["Stack", "Queue", "Binary tree", "Hash table"], 1,
                 "BFS visits nodes level by level using a FIFO queue."),
                ("Removing an element from a queue is called:", ["Push", "Pop", "Dequeue", "Peek"], 2,
                 "Enqueue adds at the rear, dequeue removes at the front."),
            ],
            "short": [
                ("Which data structure does a program's function call mechanism use?", "Stack", ["stack"],
                 "Each call pushes an activation record onto the call stack."),
            ],
            "cards": [
                ("Circular queue", "A queue in a fixed array where the rear wraps to the start to reuse space."),
                ("Stack overflow", "Pushing onto a full stack, or recursion too deep for the call stack."),
                ("Priority queue", "Dequeues the element with the highest priority; usually built on a heap."),
            ],
        },
        "Trees": {
            "mcq": [
                ("In-order traversal of a binary search tree visits keys in:", ["Random order", "Descending order", "Ascending order", "Level order"], 2,
                 "Left subtree, node, right subtree."),
                ("The height of a balanced binary tree with n nodes is about:", ["n", "log2 n", "n/2", "sqrt n"], 1,
                 "Each level doubles the number of nodes."),
                ("A binary heap is usually stored in:", ["A linked list", "An array", "A hash table", "A stack"], 1,
                 "Children of index i are at 2i+1 and 2i+2."),
                ("Which tree keeps itself balanced using rotations based on height differences?", ["AVL tree", "Binary heap", "Trie", "Full binary tree"], 0,
                 "AVL trees keep the balance factor within -1..1."),
                ("A node with no children is called a:", ["Root", "Leaf", "Parent", "Sibling"], 1,
                 "Leaves are at the bottom of the tree."),
            ],
            "short": [
                ("Which traversal visits the root before its subtrees?", "Pre-order", ["pre-order", "preorder", "pre order"],
                 "Pre-order: node, left, right."),
            ],
            "cards": [
                ("BST property", "Every key in the left subtree is smaller, every key in the right subtree is larger."),
                ("Heap property (max-heap)", "Every parent is greater than or equal to its children."),
                ("Tree height", "Number of edges on the longest path from root to a leaf."),
            ],
        },
        "Sorting": {
            "mcq": [
                ("Which sort has worst case O(n^2) but average O(n log n)?", ["Merge sort", "Quick sort", "Heap sort", "Counting sort"], 1,
                 "A poor pivot choice gives quadratic behaviour."),
                ("Which sorting algorithm is stable and always O(n log n)?", ["Quick sort", "Selection sort", "Merge sort", "Heap sort"], 2,
                 "Merge sort preserves the order of equal keys."),
                ("Bubble sort's best case on an already sorted list (with early exit) is:", ["O(1)", "O(n)", "O(n log n)", "O(n^2)"], 1,
                 "One pass with no swaps confirms the list is sorted."),
                ("Which sort repeatedly selects the minimum and places it at the front?", ["Insertion sort", "Selection sort", "Shell sort", "Radix sort"], 1,
                 "Selection sort always does O(n^2) comparisons."),
            ],
            "short": [
                ("Name the divide-and-conquer sort that splits the list in half and merges sorted halves.", "Merge sort", ["merge"],
                 "Merge sort needs O(n) extra space."),
            ],
            "cards": [
                ("Stable sort", "Keeps equal elements in their original relative order."),
                ("In-place sort", "Uses O(1) extra memory beyond the input, e.g. heap sort."),
                ("Pivot", "The element quick sort partitions around."),
            ],
        },
    },
    "ICT 1101": {
        "Variables and types": {
            "mcq": [
                ("Which of these is a valid variable name in most languages?", ["2total", "total_2", "total-2", "total 2"], 1,
                 "Names cannot start with a digit or contain spaces or hyphens."),
                ("Which data type stores whole numbers?", ["float", "int", "char", "boolean"], 1,
                 "int holds integers; float holds decimals."),
                ("A variable whose value cannot change after assignment is a:", ["Global", "Constant", "Parameter", "Pointer"], 1,
                 "Declared with const or final in many languages."),
                ("The result of 7 / 2 using integer division is:", ["3.5", "3", "4", "1"], 1,
                 "Integer division discards the remainder."),
                ("The result of 7 % 2 is:", ["3", "1", "0", "3.5"], 1,
                 "% gives the remainder of division."),
            ],
            "short": [
                ("Which data type holds only the values true and false?", "Boolean", ["bool"],
                 "Named after George Boole."),
            ],
            "cards": [
                ("Type casting", "Converting a value from one data type to another, e.g. int to float."),
                ("Scope", "The part of a program where a variable can be used."),
                ("Modulus operator", "% returns the remainder after division."),
            ],
        },
        "Control structures": {
            "mcq": [
                ("Which loop always executes its body at least once?", ["for", "while", "do-while", "foreach"], 2,
                 "The condition is checked after the body."),
                ("Which statement exits a loop immediately?", ["continue", "break", "return 0", "skip"], 1,
                 "continue skips to the next iteration instead."),
                ("How many times does the loop for (i = 0; i < 5; i++) run?", ["4", "5", "6", "Infinite"], 1,
                 "i takes values 0 to 4."),
                ("Which structure chooses between many fixed values of one variable?", ["if", "switch", "while", "for"], 1,
                 "switch (or match) branches on discrete cases."),
            ],
            "short": [
                ("Which keyword skips the rest of the current loop iteration?", "continue", ["continue"],
                 "Execution jumps to the next iteration."),
            ],
            "cards": [
                ("Infinite loop", "A loop whose condition never becomes false."),
                ("Nested loop", "A loop inside another loop; total iterations multiply."),
                ("Sentinel value", "A special input value that signals the end of data entry."),
            ],
        },
        "Functions": {
            "mcq": [
                ("Values passed into a function when it is called are:", ["Parameters", "Arguments", "Returns", "Locals"], 1,
                 "Parameters are the names in the definition; arguments are the values passed."),
                ("A function that calls itself is:", ["Iterative", "Recursive", "Overloaded", "Inline"], 1,
                 "Recursion needs a base case to stop."),
                ("What does a void function return?", ["0", "Nothing", "NULL pointer", "An empty string"], 1,
                 "void means no return value."),
                ("Defining several functions with the same name but different parameters is:", ["Overriding", "Overloading", "Recursion", "Encapsulation"], 1,
                 "The compiler picks the version by its parameter list."),
            ],
            "short": [
                ("What is the condition that stops a recursive function called?", "Base case", ["base"],
                 "Without it the recursion never ends."),
            ],
            "cards": [
                ("Pass by value", "The function receives a copy; changes do not affect the caller's variable."),
                ("Pass by reference", "The function receives a reference; changes affect the caller's variable."),
                ("Return statement", "Ends the function and sends a value back to the caller."),
            ],
        },
        "Arrays": {
            "mcq": [
                ("In most languages, the index of the first array element is:", ["1", "0", "-1", "Depends on size"], 1,
                 "Zero-based indexing is standard in C, Java, Python and Dart."),
                ("Accessing index 10 of an array of length 10 causes:", ["The last element", "An out-of-bounds error", "The first element", "NULL"], 1,
                 "Valid indices are 0 to 9."),
                ("A two-dimensional array is best described as:", ["A list of lists (rows and columns)", "Two separate arrays", "A linked list", "A stack"], 0,
                 "Elements are accessed with two indices, a[row][col]."),
            ],
            "short": [
                ("What is the index of the last element in an array of length n?", "n - 1", ["n-1", "n - 1"],
                 "Because indexing starts at 0."),
            ],
            "cards": [
                ("Array", "A fixed-size, ordered collection of elements of the same type stored contiguously."),
                ("Traversal", "Visiting each element of a collection once, usually with a loop."),
            ],
        },
        "Problem solving": {
            "mcq": [
                ("A step-by-step procedure for solving a problem is an:", ["Algorithm", "Compiler", "Interpreter", "IDE"], 0,
                 "Programs implement algorithms."),
                ("Which diagram uses a diamond for a decision?", ["UML class diagram", "Flowchart", "ER diagram", "Gantt chart"], 1,
                 "Flowcharts use diamonds for decisions and rectangles for processes."),
                ("Pseudocode is:", ["Machine code", "An informal, language-neutral description of an algorithm", "A compiled language", "A debugging tool"], 1,
                 "It focuses on logic, not syntax."),
                ("An error that makes a program produce wrong output without crashing is a:", ["Syntax error", "Logic error", "Compile error", "Linker error"], 1,
                 "Logic errors are found by testing, not by the compiler."),
            ],
            "short": [
                ("What program translates the whole of a high-level program into machine code before it runs?", "Compiler", ["compiler"],
                 "An interpreter translates and runs line by line instead."),
            ],
            "cards": [
                ("Syntax error", "Code that breaks the language's grammar; the program will not compile or run."),
                ("Dry run", "Tracing an algorithm by hand with sample values to check its logic."),
                ("Decomposition", "Breaking a problem into smaller, manageable sub-problems."),
            ],
        },
    },
    "CMP 110": {
        "Programming basics": {
            "mcq": [
                ("Which symbol usually ends a statement in C, Java and Dart?", [":", ";", ".", ","], 1,
                 "The semicolon terminates statements."),
                ("Comments in code are:", ["Executed first", "Ignored by the compiler", "Required for compilation", "Converted to output"], 1,
                 "Comments explain code to humans."),
                ("An IDE is:", ["A programming language", "An integrated development environment", "An operating system", "A database"], 1,
                 "Examples: VS Code, Android Studio."),
                ("The entry point of a C or Java program is the function named:", ["start", "main", "init", "run"], 1,
                 "Execution begins at main."),
            ],
            "short": [
                ("What do we call a mistake in a program?", "Bug", ["bug"],
                 "Finding and fixing them is debugging."),
            ],
            "cards": [
                ("Source code", "Human-readable instructions written in a programming language."),
                ("Debugging", "Finding and fixing errors in a program."),
                ("Interpreter", "Translates and executes a program one statement at a time."),
            ],
        },
        "Operators and expressions": {
            "mcq": [
                ("What is the value of 2 + 3 * 4?", ["20", "14", "24", "9"], 1,
                 "Multiplication has higher precedence than addition."),
                ("Which operator tests equality in most C-like languages?", ["=", "==", "=>", "!="], 1,
                 "= assigns; == compares."),
                ("The logical AND of true and false is:", ["true", "false", "null", "error"], 1,
                 "AND is true only when both operands are true."),
                ("x += 3 is equivalent to:", ["x = 3", "x = x + 3", "x == x + 3", "x = 3x"], 1,
                 "Compound assignment combines an operator with assignment."),
            ],
            "short": [
                ("Which operator gives the remainder of a division?", "%", ["%", "modulus", "mod"],
                 "Also called the modulus operator."),
            ],
            "cards": [
                ("Operator precedence", "The order in which operators are evaluated, e.g. * before +."),
                ("Relational operators", "<, >, <=, >=, ==, != compare values and give a boolean."),
            ],
        },
        "Selection": {
            "mcq": [
                ("In the statement if (a > b) x = a; else x = b; what does x end up as?", ["The smaller value", "The larger value", "Always a", "Always b"], 1,
                 "This computes the maximum of a and b."),
                ("Which of these is a ternary expression?", ["a ? b : c", "a && b", "a ?? b", "a => b"], 0,
                 "condition ? valueIfTrue : valueIfFalse."),
                ("A switch case without break in C will:", ["Stop", "Fall through to the next case", "Raise an error", "Repeat"], 1,
                 "Execution continues into the following case."),
            ],
            "short": [
                ("Which keyword introduces the alternative branch of an if statement?", "else", ["else"],
                 "else runs when the if condition is false."),
            ],
            "cards": [
                ("Nested if", "An if statement inside another if or else branch."),
                ("Boolean expression", "An expression that evaluates to true or false."),
            ],
        },
        "Iteration": {
            "mcq": [
                ("Which loop is best when the number of iterations is known in advance?", ["while", "do-while", "for", "goto"], 2,
                 "for keeps initialisation, condition and update together."),
                ("What does this code print?  i = 1; while (i < 4) { print(i); i++; }", ["1 2 3", "1 2 3 4", "0 1 2 3", "Nothing"], 0,
                 "The loop stops when i becomes 4."),
                ("A counter variable in a loop is used to:", ["Store input", "Track the number of iterations", "End the program", "Declare functions"], 1,
                 "It is updated on every pass."),
            ],
            "short": [
                ("What is a loop called that never terminates?", "Infinite loop", ["infinite"],
                 "Usually caused by a condition that never becomes false."),
            ],
            "cards": [
                ("Accumulator", "A variable that collects a running total inside a loop."),
                ("Loop invariant", "A condition that holds before and after every iteration."),
            ],
        },
        "Data structures intro": {
            "mcq": [
                ("Which structure stores key-value pairs?", ["Array", "Map (dictionary)", "Stack", "Queue"], 1,
                 "Values are looked up by key."),
                ("A string is essentially a sequence of:", ["Integers", "Characters", "Booleans", "Arrays of floats"], 1,
                 "Strings are ordered collections of characters."),
                ("Which list operation adds an item to the end?", ["append/add", "pop", "insert at 0", "clear"], 0,
                 "add() in Dart, append() in Python."),
            ],
            "short": [
                ("What is the term for the number of characters in a string?", "Length", ["length", "len"],
                 "Most languages expose it as .length or len()."),
            ],
            "cards": [
                ("List", "An ordered, resizable collection that allows duplicates."),
                ("Set", "An unordered collection with no duplicate elements."),
                ("Map", "A collection of key-value pairs with unique keys."),
            ],
        },
    },
}
