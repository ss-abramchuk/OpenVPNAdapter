# Objective-C Style Guide
> Based on [Google Objective-C Style Guide](http://google.github.io/styleguide/objcguide.html) and [NYTimes Objective-C Style Guide](https://github.com/NYTimes/objective-c-style-guide)

The purpose of this part is to describe the Objective-C (and Objective-C++) coding guidelines and practices that should be used for iOS and OS X code. Apple has already written a very good, and widely accepted, [Cocoa Coding Guidelines](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html#//apple_ref/doc/uid/10000146i) for Objective-C. Please read it in addition to this guide.

## Spacing and Formatting

### Spaces vs. Tabs
Use only spaces, and indent 4 spaces at a time. We use spaces for indentation. Do not use tabs in your code.

### Line Length
The maximum line length for Objective-C files is 125 columns.
You can make violations easier to spot by enabling **Preferences** > **Text Editing** > **Page guide at column: 125** in Xcode.

### Conditionals
Include a space after if, while, for, and switch, and around comparison operators.

```
// GOOD:

for (int i = 0; i < 5; ++i) {
    ...
}

while (test) {
    ...
}
```

Conditional bodies **MUST** use braces even when a conditional body could be written without braces (e.g., it is one line only) to prevent errors.

```
// GOOD:

if (!error) { return success; }
```

```
// AVOID:

if (!error)
    return success;

if (!error) return success;
```

### Ternary Operator
The intent of the ternary operator is to increase clarity or code neatness. The ternary **SHOULD** only evaluate a single condition per expression. Evaluating multiple conditions is usually more understandable as an if statement or refactored into named variables.

```
// GOOD:

result = a > b ? x : y;
```

```
// AVOID:

result = a > b ? x = c > d ? c : d : y;
```

### Expressions
Use a space around binary operators and assignments. Omit a space for a unary operator. Do not add spaces inside parentheses.

```
// GOOD:

x = 0;
v = w * x + y / z;
v = -y * (x + z);
```

### Variables
Asterisks indicating a type is a pointer **MUST** be "attached to" the variable name or `const` keyword. For example, `NSString *text` or `NSString *const NYTConstantString`, not `NSString* text` or `NSString * text`.

When it comes to the variable qualifiers introduced with ARC, the qualifier (`__strong`, `__weak`, `__unsafe_unretained`, `__autoreleasing`) **SHOULD** be placed at the beginning of declaration, e.g., `__weak NSString * text`

### Properties
Property definitions **SHOULD** be used in place of naked instance variables whenever possible. Direct instance variable access **SHOULD** be avoided except in initializer methods (`init`, `initWithCoder:`, etc…), `dealloc` methods and within custom setters and getters.

```
// GOOD:

@interface NYTSection: NSObject

@property (nonatomic, nullable) NSString *headline;

@end
```

```
// AVOID:

@interface NYTSection : NSObject {
    NSString *headline;
}
```

Dot notation is **RECOMMENDED** over bracket notation for getting and setting properties.

```
// GOOD:

view.backgroundColor = [UIColor orangeColor];
[UIApplication sharedApplication].delegate;
```

```
// AVOID:

[view setBackgroundColor:[UIColor orangeColor]];
UIApplication.sharedApplication.delegate;
```

### Method Declarations and Definitions
One space should be used between the - or + and the return type, and no spacing in the parameter list except between parameters.

Methods should look like this:

```
// GOOD:

- (void)doSomethingWithString:(NSString *)theString {
    ...
}
```

Asterisks indicating a type is a pointer **MUST** be "attached to" the argument name.

When it comes to the nullability specifiers, the specifiers (`nonnull`, `nullable`, `null_unspecified`) **SHOULD** be placed immediately after an open parenthesis, as long as the type is a simple object or block pointer:

```
- (void)doSomethingWithString:(nonnull NSString *)theString;
```

You can mark certain regions of your Objective-C header files as audited for `nullability` using `NS_ASSUME_NONNULL_BEGIN` and `NS_ASSUME_NONNULL_END`. Within these regions, any simple pointer type will be assumed to be `nonnull`.

```
NS_ASSUME_NONNULL_BEGIN

@interface AAPLList : NSObject <NSCoding, NSCopying>

// ...

- (nullable AAPLListItem *)itemWithName:(NSString *)name;
- (NSInteger)indexOfItem:(AAPLListItem *)item;

@property (copy, nullable) NSString *name;
@property (copy, readonly) NSArray *allItems;

// ...

@end

NS_ASSUME_NONNULL_END

```

If you have too many parameters to fit on one line, giving each its own line is preferred. If multiple lines are used, align each using the colon before the parameter.

```
// GOOD:

- (void)doSomethingWithFoo:(GTMFoo *)theFoo
                      rect:(NSRect)theRect
                  interval:(float)theInterval {
    ...
}
```

When the second or later parameter name is longer than the first, indent the second and later lines by at least four spaces, maintaining colon alignment:

```
// GOOD:

- (void)short:(GTMFoo *)theFoo
          longKeyword:(NSRect)theRect
    evenLongerKeyword:(float)theInterval
                error:(NSError **)theError {
    ...
}
```

### Method Invocations
Method invocations should be formatted much like method declarations. When there’s a choice of formatting styles, follow the convention already used in a given source file. Invocations should have all arguments on one line:

```
// GOOD:

[myObject doFooWith:arg1 name:arg2 error:arg3];
```

or have one argument per line, with colons aligned:

```
// GOOD:

[myObject doFooWith:arg1
               name:arg2
              error:arg3];
```

Don’t use any of these styles:

```
// AVOID:

[myObject doFooWith:arg1 name:arg2  // some lines with >1 arg
              error:arg3];

[myObject doFooWith:arg1
               name:arg2 error:arg3];

[myObject doFooWith:arg1
          name:arg2  // aligning keywords instead of colons
          error:arg3];
```

As with declarations and definitions, when the first keyword is shorter than the others, indent the later lines by at least four spaces, maintaining colon alignment:

```
// GOOD:

[myObj short:arg1
          longKeyword:arg2
    evenLongerKeyword:arg3
                error:arg4];
```

### Function Calls
Function calls should include as many parameters as fit on each line, except where shorter lines are needed for clarity or documentation of the parameters. Continuation lines for function parameters may be indented to align with the opening parenthesis, or may have a four-space indent.

```
// GOOD:

CFArrayRef array = CFArrayCreate(kCFAllocatorDefault, objects, numberOfObjects,
                                 &kCFTypeArrayCallBacks);

NSString *string = NSLocalizedStringWithDefaultValue(@"FEET", @"DistanceTable",
    resourceBundle,  @"%@ feet", @"Distance for multiple feet");

UpdateTally(scores[x] * y + bases[x],  // Score heuristic.
            x, y, z);

TransformImage(image,
               x1, x2, x3,
               y1, y2, y3,
               z1, z2, z3);
```

Use local variables with descriptive names to shorten function calls and reduce nesting of calls.

```
// GOOD:

double scoreHeuristic = scores[x] * y + bases[x];
UpdateTally(scoreHeuristic, x, y, z);
```

### Error Handling
When methods return an error parameter by reference, code **MUST** switch on the returned value and **MUST NOT** switch on the error variable.

```
// GOOD:

NSError *error;
if (![self trySomethingWithError:&error]) {
    // Handle Error
}
```

```
// AVOID:

NSError *error;
[self trySomethingWithError:&error];
if (error) {
    // Handle Error
}
```

### Exceptions
Format exceptions with `@catch` and `@finally` labels on the same line as the preceding }. Add a space between the @ label and the opening brace (`{`), as well as between the `@catch` and the caught object declaration. If you must use Objective-C exceptions, format them as follows.

```
// GOOD:

@try {
    foo();
} @catch (NSException *ex) {
    bar(ex);
} @finally {
    baz();
}
```

### Function Length
Prefer small and focused functions.

Long functions and methods are occasionally appropriate, so no hard limit is placed on function length. If a function exceeds about 40 lines, think about whether it can be broken up without harming the structure of the program.

Even if your long function works perfectly now, someone modifying it in a few months may add new behavior. This could result in bugs that are hard to find. Keeping your functions short and simple makes it easier for other people to read and modify your code.

When updating legacy code, consider also breaking long functions into smaller and more manageable pieces.

### Vertical Whitespace
Use vertical whitespace sparingly. To allow more code to be easily viewed on a screen, avoid putting blank lines just inside the braces of functions. Limit blank lines to one or two between functions and between logical groups of code.

## Naming
Names should be as descriptive as possible, within reason. Follow standard [Objective-C naming rules](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).

Avoid non-standard abbreviations. Don’t worry about saving horizontal space as it is far more important to make your code immediately understandable by a new reader. For example:

```
// GOOD:

int numberOfErrors = 0;
int completedConnectionsCount = 0;
tickets = [[NSMutableArray alloc] init];
userInfo = [someObject object];
port = [network port];
NSDate *gAppLaunchDate;
```

```
// AVOID:

int w;
int nerr;
int nCompConns;
tix = [[NSMutableArray alloc] init];
obj = [someObject object];
p = [network port];
```

Any class, category, method, function, or variable name should use all capitals for acronyms and initialisms within the name. This follows Apple’s standard of using all capitals within a name for acronyms such as URL, ID, TIFF, and EXIF.

Names of C functions and typedefs should be capitalized and use camel case as appropriate for the surrounding code.

### File Names
File names should reflect the name of the class implementation that they contain, including case.

Files containing code that may be shared across projects or used in a large project should have a clearly unique name, typically including the project or class prefix.

File names for categories should include the name of the class being extended, like `GTMNSString+Utils.h` or `NSTextView+GTMAutocomplete.h`

### Class Names
Class names (along with category and protocol names) should start as uppercase and use mixed case to delimit words.

When designing code to be shared across multiple applications, prefixes are acceptable and recommended (e.g. GTMSendMessage). Prefixes are also recommended for classes of large applications that depend on external libraries.

### Category Names
Category names should start with a prefix identifying the category as part of a project or open for general use.

The category name should incorporate the name of the class it’s extending. For example, if we want to create a category on `NSString` for parsing, we would put the category in a file named `NSString+GTMParsing.h`, and the category itself would be named `GTMNSStringParsingAdditions`. The file name and the category may not match, as this file could have many separate categories related to parsing. Methods in that category should share the prefix (`gtm_MyCategoryMethodOnAString:`) in order to prevent collisions in Objective-C’s global namespace.

```
// GOOD:

/** A category that adds parsing functionality to NSString. */
@interface NSString (GTMNSStringParsingAdditions)
- (NSString *)gtm_parsedString;
@end
```

### Objective-C Method Names
Method and parameter names typically start as lowercase and then use mixed case.

Proper capitalization should be respected, including at the beginning of names.

```
// GOOD:

+ (NSURL *)URLWithString:(NSString *)URLString;
```

The method name should read like a sentence if possible, meaning you should choose parameter names that flow with the method name. Objective-C method names tend to be very long, but this has the benefit that a block of code can almost read like prose, thus rendering many implementation comments unnecessary.

Use prepositions and conjunctions like “with”, “from”, and “to” in the second and later parameter names only where necessary to clarify the meaning or behavior of the method.

```
- (void)addTarget:(id)target action:(SEL)action;
- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;
- (void)replaceCharactersInRange:(NSRange)aRange
            withAttributedString:(NSAttributedString *)attributedString;
```

A method that returns an object should have a name beginning with a noun identifying the object returned:

```
// GOOD:

- (Sandwich *)sandwich;
```

```
// AVOID:

- (Sandwich *)makeSandwich;
```

An accessor method should be named the same as the object it’s getting, but it should not be prefixed with the word get. For example:

```
// GOOD:

- (id)delegate;
```

```
// AVOID:

- (id)getDelegate;
```

Accessors that return the value of boolean adjectives have method names beginning with `is`, but property names for those methods omit the `is`.

```
// GOOD:

@property(nonatomic, getter=isGlorious) BOOL glorious;
- (BOOL)isGlorious;

BOOL isGood = object.glorious;
BOOL isGood = [object isGlorious];
```

```
// AVOID:

BOOL isGood = object.isGlorious;
```

Dot notation is used only with property names, not with method names.

```
// GOOD:

NSArray<Frog *> *frogs = [NSArray<Frog *> arrayWithObject:frog];
NSEnumerator *enumerator = [frogs reverseObjectEnumerator];
```

```
// AVOID:

NSEnumerator *enumerator = frogs.reverseObjectEnumerator;
```

These guidelines are for Objective-C methods only. C++ method names continue to follow the rules set in the C++ style guide.

### Function Names
Regular functions have mixed case.

Ordinarily, functions should start with a capital letter and have a capital letter for each new word (a.k.a. “Camel Case” or “Pascal case”).

```
// GOOD:

static void AddTableEntry(NSString *tableEntry);
static BOOL DeleteFile(char *filename);
```

Because Objective-C does not provide namespacing, non-static functions should have a prefix that minimizes the chance of a name collision.

```
// GOOD:

extern NSTimeZone *GTMGetDefaultTimeZone();
extern NSString *GTMGetURLScheme(NSURL *URL);
```

### Variable Names
Variable names typically start with a lowercase and use mixed case to delimit words.

Instance variables have leading underscores. File scope or global variables have a prefix `g`. For example: `myLocalVariable`, `_myInstanceVariable`, `gMyGlobalVariable`.

#### Common Variable Names
Readers should be able to infer the variable type from the name, but do not use Hungarian notation for syntactic attributes, such as the static type of a variable (int or pointer).

File scope or global variables (as opposed to constants) declared outside the scope of a method or function should be rare, and should have the prefix `g`.

```
// GOOD:

static int gGlobalCounter;
```

#### Instance Variables
Instance variable names are mixed case and should be prefixed with an underscore, like `_usernameTextField`.

#### Constants
Constant symbols (const global and static variables and constants created with #define) should use mixed case to delimit words.

Global and file scope constants should have an appropriate prefix.

```
// GOOD:

extern NSString *const GTLServiceErrorDomain;

typedef NS_ENUM(NSInteger, GTLServiceError) {
    GTLServiceErrorQueryResultMissing = -3000,
    GTLServiceErrorWaitTimedOut       = -3001,
};
```

Because Objective-C does not provide namespacing, constants with external linkage should have a prefix that minimizes the chance of a name collision, typically like `ClassNameConstantName` or `ClassNameEnumName`.

For interoperability with Swift code, enumerated values should have names that extend the typedef name:

```
// GOOD:

typedef NS_ENUM(NSInteger, DisplayTinge) {
    DisplayTingeGreen = 1,
    DisplayTingeBlue = 2,
};
```

Constants may use a lowercase k prefix when appropriate:

```
// GOOD:

static const int kFileCount = 12;
static NSString *const kUserKey = @"kUserKey";
```

## Types and Declarations

### Local Variables
Declare variables in the narrowest practical scopes, and close to their use. Initialize variables in their declarations.

```
// GOOD:

CLLocation *location = [self lastKnownLocation];
for (int meters = 1; meters < 10; meters++) {
  reportFrogsWithinRadius(location, meters);
}
```

Under Automatic Reference Counting, pointers to Objective-C objects are by default initialized to `nil`, so explicit initialization to `nil` is not required.

### Unsigned Integers
Avoid unsigned integers except when matching types used by system interfaces.

Subtle errors crop up when doing math or counting down to zero using unsigned integers. Rely only on signed integers in math expressions except when matching `NSUInteger` in system interfaces.

```
// GOOD:

NSUInteger numberOfObjects = array.count;
for (NSInteger counter = numberOfObjects - 1; counter > 0; --counter)
```

```
// AVOID:

for (NSUInteger counter = numberOfObjects - 1; counter > 0; --counter)
```

Unsigned integers may be used for flags and bitmasks, though often `NS_OPTIONS` or `NS_ENUM` will be more appropriate.

### Types with Inconsistent Sizes
Due to sizes that differ in 32- and 64-bit builds, avoid types `long`, `NSInteger`, `NSUInteger`, and `CGFloat` except when matching system interfaces.

Types `long`, `NSInteger`, `NSUInteger`, and `CGFloat` vary in size between 32- and 64-bit builds. Use of these types is appropriate when handling values exposed by system interfaces, but they should be avoided for most other computations.

```
// GOOD:

int32_t scalar1 = proto.intValue;
int64_t scalar2 = proto.longValue;
NSUInteger numberOfObjects = array.count;
CGFloat offset = view.bounds.origin.x;
```

```
// AVOID:

NSInteger scalar2 = proto.longValue;
```

File and buffer sizes often exceed 32-bit limits, so they should be declared using `int64_t`, not with `long`, `NSInteger`, or `NSUInteger`.

## Comments
Comments are absolutely vital to keeping our code readable. The following rules describe what you should comment and where. But remember: while comments are important, the best code is self-documenting. Giving sensible names to types and variables is much better than using obscure names and then trying to explain them through comments.

Pay attention to punctuation, spelling, and grammar; it is easier to read well-written comments than badly written ones.

Comments should be as readable as narrative text, with proper capitalization and punctuation. In many cases, complete sentences are more readable than sentence fragments. Shorter comments, such as comments at the end of a line of code, can sometimes be less formal, but use a consistent style. When writing your comments, write for your audience: the next contributor who will need to understand your code. Be generous—the next one may be you!

### File Comments
A file may optionally start with a description of its contents. Every file may contain the following items, in order:

- License boilerplate if necessary. Choose the appropriate boilerplate for the license used by the project.
- A basic description of the contents of the file if necessary.

If you make significant changes to a file with an author line, consider deleting the author line since revision history already provides a more detailed and accurate record of authorship.

### Declaration Comments
Every non-trivial interface, public and private, should have an accompanying comment describing its purpose and how it fits into the larger picture.

Comments should be used to document classes, properties, ivars, functions, categories, protocol declarations, and enums.

```
// GOOD:

/**
 * A delegate for NSApplication to handle notifications about app
 * launch and shutdown. Owned by the main app controller.
 */
@interface MyAppDelegate : NSObject {
  /**
   * The background task in progress, if any. This is initialized
   * to the value UIBackgroundTaskInvalid.
   */
  UIBackgroundTaskIdentifier _backgroundTaskID;
}

/** The factory that creates and manages fetchers for the app. */
@property(nonatomic) GTMSessionFetcherService *fetcherService;

@end
```

Doxygen-style comments are encouraged for interfaces as they are parsed by Xcode to display formatted documentation. There is a wide variety of Doxygen commands; use them consistently within a project.

If you have already described an interface in detail in the comments at the top of your file, feel free to simply state, “See comment at top of file for a complete description”, but be sure to have some sort of comment.

Additionally, each method should have a comment explaining its function, arguments, return value, thread or queue assumptions, and any side effects. Documentation comments should be in the header for public methods, or immediately preceding the method for non-trivial private methods.

Use descriptive form (“Opens the file”) rather than imperative form (“Open the file”) for method and function comments. The comment describes the function; it does not tell the function what to do.

Document the thread usage assumptions the class, properties, or methods make, if any. If an instance of the class can be accessed by multiple threads, take extra care to document the rules and invariants surrounding multithreaded use.

Any sentinel values for properties and ivars, such as `NULL` or `-1`, should be documented in comments.

Declaration comments explain how a method or function is used. Comments explaining how a method or function is implemented should be with the implementation rather than with the declaration.

### Implementation Comments
Provide comments explaining tricky, subtle, or complicated sections of code.

```
// GOOD:

// Set the property to nil before invoking the completion handler to
// avoid the risk of reentrancy leading to the callback being
// invoked again.
CompletionHandler handler = self.completionHandler;
self.completionHandler = nil;
handler();
```

When useful, also provide comments about implementation approaches that were considered or abandoned.

End-of-line comments should be separated from the code by at least 2 spaces. If you have several comments on subsequent lines, it can often be more readable to line them up.

```
// GOOD:

[self doSomethingWithALongName];  // Two spaces before the comment.
[self doSomethingShort];          // More spacing to align the comment.
```

### Disambiguating Symbols
Where needed to avoid ambiguity, use backticks or vertical bars to quote variable names and symbols in comments in preference to using quotation marks or naming the symbols inline.

In Doxygen-style comments, prefer demarcating symbols with a monospace text command, such as `@c`.

Demarcation helps provide clarity when a symbol is a common word that might make the sentence read like it was poorly constructed. A common example is the symbol `count`:

```
// GOOD:

// Sometimes `count` will be less than zero.
```

or when quoting something which already contains quotes

```
// GOOD:

// Remember to call `StringWithoutSpaces("foo bar baz")`
```

Backticks or vertical bars are not needed when a symbol is self-apparent.

```
// GOOD:

// This class serves as a delegate to GTMDepthCharge.
```

Doxygen formatting is also suitable for identifying symbols.

```
// GOOD:

/** @param maximum The highest value for @c count. */
```

## C Language Features

### Macros
Avoid macros, especially where `const` variables, enums, XCode snippets, or C functions may be used instead.

Macros make the code you see different from the code the compiler sees. Modern C renders traditional uses of macros for constants and utility functions unnecessary. Macros should only be used when there is no other solution available.

Where a macro is needed, use a unique name to avoid the risk of a symbol collision in the compilation unit. If practical, keep the scope limited by `#undefining` the macro after its use.

Macro names should use `SHOUTY_SNAKE_CASE` – all uppercase letters with underscores between words. Function-like macros may use C function naming practices. Do not define macros that appear to be C or Objective-C keywords.

```
// GOOD:

#define GTM_EXPERIMENTAL_BUILD ...

// Assert unless X > Y
#define GTM_ASSERT_GT(X, Y) ...

// Assert unless X > Y
#define GTMAssertGreaterThan(X, Y) ...
```

```
// AVOID:

#define kIsExperimentalBuild ...

#define unless(X) if(!(X))
```

Avoid macros that expand to unbalanced C or Objective-C constructs. Avoid macros that introduce scope, or may obscure the capturing of values in blocks.

Avoid macros that generate class, property, or method definitions in headers to be used as public API. These only make the code hard to understand, and the language already has better ways of doing this.

Avoid macros that generate method implementations, or that generate declarations of variables that are later used outside of the macro. Macros shouldn’t make code hard to understand by hiding where and how a variable is declared.

```
// AVOID:

#define ARRAY_ADDER(CLASS) \
    -(void)add ## CLASS ## :(CLASS *)obj toArray:(NSMutableArray *)array

ARRAY_ADDER(NSString) {
    if (array.count > 5) {
        ...
    }
}
```

Examples of acceptable macro use include assertion and debug logging macros that are conditionally compiled based on build settings – often, these are not compiled into release builds.
