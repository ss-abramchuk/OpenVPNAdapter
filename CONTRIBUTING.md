# Objective-C Style Guide

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
Asterisks indicating a type is a pointer **MUST** be "attached to" the variable name. For example, `NSString *text` or `NSString *const NYTConstantString`, not `NSString* text` or `NSString * text`.

When it comes to the variable qualifiers introduced with ARC, the qualifier (`__strong`, `__weak`, `__unsafe_unretained`, `__autoreleasing`) **SHOULD** be placed between the asterisks and the variable name, e.g., `NSString * __weak text`

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

Dot notation is RECOMMENDED over bracket notation for getting and setting properties.

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

Asterisks indicating a type is a pointer MUST be "attached to" the argument name.

When it comes to the nullability specifiers, the specifiers (`__nullable`, `__nonnull`, `__null_unspecified`) **SHOULD** be placed between the asterisks and the argument name:

```
- (void)doSomethingWithString:(NSString * __nullable)theString;
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
