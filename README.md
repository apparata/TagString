# TagString

![license](https://img.shields.io/badge/license-MIT-blue.svg) ![language Swift 3](https://img.shields.io/badge/language-Swift%203-orange.svg) ![platform iOS macOS tvOS](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20macOS-lightgrey.svg)

The `TagString` struct is a wrapper around strings that contain simple markup for the purpose of easily creating `NSAttributedString`s.

Tags can be nested. Attributes take precedence inside and out.

Tags are written with angular brackets `<tag>`. Closing tag names begin with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular brackets, as in HTML. `&amp;` escapes &.

## Example

Using TagString struct:

```Swift
let attributes: [String: [String: AnyObject]] = [
    "loud": [NSFontAttributeName: UIFont.systemFont(ofSize: 40)],
    "green": [NSForegroundColorAttributeName: UIColor.green]
]

let string: TagString = "Testing <loud>this <green>text</green></loud> thing."
string.attributed(with: attributes)
```

Using String extension:

```Swift
let attributes: [String: [String: AnyObject]] = [
    "loud": [NSFontAttributeName: UIFont.systemFont(ofSize: 40)],
    "green": [NSForegroundColorAttributeName: UIColor.green]
]

let string = "Testing <loud>this <green>text</green></loud> thing.".attributed(with: attributes)
```
