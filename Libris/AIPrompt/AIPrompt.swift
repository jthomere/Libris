//
//  AIPrompt.swift
//  Libris
//
//  Builds the self-contained prompt the user hands to an AI assistant so it
//  produces a JSON file Libris can import. The prompt carries the current
//  import schema version and the genres already in the library, so it always
//  matches what the app accepts.
//

import Foundation

enum AIPrompt {
    static func text(genres: [String]) -> String {
        let version = ImportParser.latestVersion

        var sections: [String] = []

        sections.append("""
        I'm going to give you one or more photos of books — for example a display or shelf in a bookstore. From the photos, produce a single JSON file I can import into my library app, Libris. Reply with only the JSON, nothing else.
        """)

        sections.append("""
        Top-level shape — a JSON object with two keys:

        {
          "schemaVersion": \(version),
          "books": [ { … }, { … } ]
        }

        - "schemaVersion": always the number \(version).
        - "books": one object per book.
        """)

        sections.append("""
        Each book — every field is optional. Omit a field entirely rather than sending an empty value. Unknown fields are ignored.

        - "title" (string): the book's title.
        - "author" (string): author name(s).
        - "isbn" (string): the ISBN, 10 or 13 digits. Hyphens and spaces are fine. Send it as a string so a leading zero or trailing "X" is preserved.
        - "bookDescription" (string): a short synopsis.
        - "genre" (string): a single genre label.
        - "rating" (number): 0 to 5, the rating from the source (e.g. the Goodreads score). Send a plain number or omit it — never "N/A", "3.8*", or any other string.
        - "note" (string): a short note about the book.
        - "tags" (array of strings): any labels you want, e.g. ["Bestseller"].
        - "goodreadsURL" (string): full URL to the Goodreads page.
        - "amazonURL" (string): full URL to the Amazon page.
        - "coverImageURL" (string): full URL to a cover image.
        """)

        if !genres.isEmpty {
            sections.append("""
            Genres already in my library — reuse one of these when it fits, so labels stay consistent instead of splitting (for example "Science Fiction" vs "SF"):

            \(genres.joined(separator: ", "))
            """)
        }

        sections.append("""
        Rules:
        - The file is a batch of books to ADD. Don't include any reading status.
        - Field names are case-sensitive — match them exactly, including the capitals in "bookDescription", "goodreadsURL", "amazonURL", and "coverImageURL".
        - Encode the file as UTF-8.
        """)

        sections.append("""
        Example:

        {
          "schemaVersion": \(version),
          "books": [
            {
              "title": "Project Hail Mary",
              "author": "Andy Weir",
              "isbn": "9780593135204",
              "genre": "Science Fiction",
              "rating": 4.5,
              "bookDescription": "A lone astronaut wakes with no memory aboard a ship that…",
              "tags": ["Bestseller"],
              "goodreadsURL": "https://www.goodreads.com/book/show/54493401",
              "amazonURL": "https://www.amazon.com/dp/0593135202",
              "coverImageURL": "https://covers.openlibrary.org/b/isbn/0593135202-M.jpg"
            }
          ]
        }
        """)

        return sections.joined(separator: "\n\n")
    }
}
