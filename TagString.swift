//
//  Copyright © 2016 Apparata AB. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//  (MIT License)
//

import Foundation

public extension String {
    
    /// Returns an NSAttributedString, attributed based on markup in string
    /// and a dictionary where the tag is the key mapped to a dictionary
    /// of attributes.
    ///
    /// Tags can be nested. Attributes take precedence inside and out.
    ///
    /// Tags are writen with angular brackets `<tag>`. Closing tag names begin
    /// with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular
    /// brackets, as in HTML. `&amp;` escapes &.
    ///
    /// Example:
    /// ```
    /// let attributes: [String: [NSAttributedStringKey: AnyObject]] = [
    ///     "loud": [.font: UIFont.systemFont(ofSize: 40)],
    ///     "green": [.color: UIColor.green]
    /// ]
    ///
    /// let string = "Testing <loud>this <green>text</green></loud> thing.".attributed(with: attributes)
    /// ```
    ///
    /// - Parameter attributes: Dictionary where tag names are used as keys
    ///                         mapped to dictionaries of string attributes.
    /// - Returns: Returns attributed string or `nil` if tags were not used
    ///            correctly (e.g. no closing tag).
    ///
    public func attributed(with attributes: TagString.Attributes) -> NSAttributedString? {
        return TagString(self).attributed(with: attributes)
    }
}

/// The `TagString` struct is a wrapper around strings that contain simple
/// markup for the purpose of easily creating `NSAttributedString`s.
///
/// Tags can be nested. Attributes take precedence inside and out.
///
/// Tags are writen with angular brackets `<tag>`. Closing tag names begin
/// with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular
/// brackets, as in HTML. `&amp;` escapes &.
///
/// Example:
/// ```
/// let attributes: [String: [NSAttributedStringKey: AnyObject]] = [
///     "loud": [.font: UIFont.systemFont(ofSize: 40)],
///     "green": [.color: UIColor.green]
/// ]
///
/// let string: TagString = "Testing <loud>this <green>text</green></loud> thing."
/// string.attributed(with: attributes)
/// ```
///
public struct TagString {
    
    public typealias Attributes = [String: [NSAttributedStringKey: AnyObject]]
    
    private enum TagStringToken {
        case text(String)
        case entity(String)
        case startTag(String)
        case endTag(String)
    }
    
    private let entities = ["lt": "<", "gt": ">", "amp": "&"]
    
    /// The raw string passed into the initializer.
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }
    
    /// Example:
    /// ```
    /// let attributes: [String: [NSAttributedStringKey: AnyObject]] = [
    ///     "loud": [.font: UIFont.systemFont(ofSize: 40)],
    ///     "green": [.foregroundColor: UIColor.green]
    /// ]
    ///
    /// let string: TagString = "Testing <loud>this <green>text</green></loud> thing."
    /// string.attributed(with: attributes)
    /// ```
    ///
    /// - Parameter attributes: Dictionary where tag names are used as keys
    ///                         mapped to dictionaries of string attributes.
    /// - Returns: Returns attributed string or `nil` if tags were not used
    ///            correctly (e.g. no closing tag).
    ///
    public func attributed(with attributes: Attributes) -> NSAttributedString? {
        if let tokenizedText = tokenize(string: self.string) {
            return buildString(tokenizedText: tokenizedText, attributes: attributes)
        } else {
            return nil
        }
    }
    
    // MARK: - Tokenizer
    
    private func tokenize(string: String) -> [TagStringToken]? {
        
        var tokens = [TagStringToken]()
        
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            if let textToken = scanText(scanner: scanner) {
                tokens.append(textToken)
            }
            
            if scanner.isAtEnd {
                break
            }
            
            if let tagToken = scanTag(scanner: scanner) {
                tokens.append(tagToken)
            } else if let entityToken = scanEntity(scanner: scanner) {
                tokens.append(entityToken)
            } else {
                return nil
            }
            
            
        }
        
        return tokens
    }
    
    private func scanTag(scanner: Scanner) -> TagStringToken? {
        guard scanner.scanString("<", into: nil) else {
            return nil
        }
        
        let isEndTag = scanner.scanString("/", into: nil)
        
        var tag: NSString?
        guard scanner.scanUpTo(">", into: &tag) else {
            return nil
        }
        
        let token: TagStringToken
        if let tag = tag as String? {
            token = isEndTag ? TagStringToken.endTag(tag) : TagStringToken.startTag(tag)
        } else {
            return nil
        }
        
        scanner.scanString(">", into: nil)
        
        return token
    }
    
    private func scanEntity(scanner: Scanner) -> TagStringToken? {
        guard scanner.scanString("&", into: nil) else {
            return nil
        }
        
        var entity: NSString?
        guard scanner.scanUpTo(";", into: &entity) else {
            return nil
        }
        
        let token: TagStringToken
        if let entity = entity as String? {
            token = TagStringToken.entity(entity)
        } else {
            return nil
        }
        
        scanner.scanString(";", into: nil)
        
        return token
        
    }
    
    private func scanText(scanner: Scanner) -> TagStringToken? {
        var text: NSString?
        let tagOrEntityCharacters = CharacterSet(charactersIn: "<&")
        if scanner.scanUpToCharacters(from: tagOrEntityCharacters, into: &text), let text = text as String? {
            return .text(text)
        }
        return nil
    }
    
    // MARK: - String builder
    
    private func buildString(tokenizedText: [TagStringToken], attributes: [String: [NSAttributedStringKey: AnyObject]]) -> NSAttributedString? {
        
        var tagStack = [String]()
        
        let outputString = NSMutableAttributedString()
        
        for token in tokenizedText {
            switch token {
                
            case .text(let string):
                let currentAttributes = buildAttributes(tagStack: tagStack, attributes: attributes)
                let attributedString = NSAttributedString(string: string, attributes: currentAttributes)
                outputString.append(attributedString)
                
            case .startTag(let tag):
                tagStack.append(tag)
                
            case .endTag(let expectedTag):
                let tag = tagStack.removeLast()
                guard tag == expectedTag else {
                    return nil
                }
                
            case .entity(let entity):
                if let string = entities[entity] {
                    let currentAttributes = buildAttributes(tagStack: tagStack, attributes: attributes)
                    let attributedString = NSAttributedString(string: string, attributes: currentAttributes)
                    outputString.append(attributedString)
                }
            }
            
        }
        
        return NSAttributedString(attributedString: outputString)
    }
    
    private func buildAttributes(tagStack: [String], attributes: [String: [NSAttributedStringKey: AnyObject]]) -> [NSAttributedStringKey: AnyObject] {
        var compoundAttributes = [NSAttributedStringKey: AnyObject]()
        for tag in tagStack {
            if let tagAttributes = attributes[tag] {
                for (key, value) in tagAttributes {
                    compoundAttributes.updateValue(value, forKey: key)
                }
            }
        }
        return compoundAttributes
    }
}

// This is what allows the TagString to be created from a literal string.
extension TagString: ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        string = "\(value)"
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        string = value
    }
    
    public init(stringLiteral value: StringLiteralType) {
        string = value
    }
}
