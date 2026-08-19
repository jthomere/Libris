//
//  AIPrompt.swift
//  Libris
//

import Foundation

enum AIPrompt {
    static func text(genres: [String], tags: [String]) -> String {
        let version = ImportParser.latestVersion

        var sections: [String] = []

        let tagsReuse = tags.isEmpty
            ? ""
            : " FYI, here are the tags I have used so far: \(tags.joined(separator: ", "))."

        sections.append("""
        I'm going to give you one or more photos of books. From the photos, produce a single JSON file.
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
        - "isbn" (string): the ISBN — ISBN-13, or ISBN-10 (which may end in "X"). Send it as a string.
        - "bookDescription" (string): a short synopsis.
        - "genre" (string): a single genre label.
        - "rating" (number): 0 to 5, the rating from the source (e.g. the Goodreads score). Send a plain number or omit it — never "N/A", "3.8*", or any other string.
        - "note" (string): a short note about the book, when visible in the photo (e.g. staff notes in a bookstore).
        - "tags" (array of strings): any labels you might see in the photos or some salient features of the book. \(tagsReuse)
        - "goodreadsURL" (string): full URL to the Goodreads page.
        - "amazonURL" (string): full URL to the Amazon page.
        - "coverImageURL" (string): full URL to a cover image.
        """)

        if !genres.isEmpty {
            sections.append("""
            Genres already in my library — you can reuse one of these when it fits:

            \(genres.joined(separator: ", "))
            """)
        }

        sections.append("""
        Rules:
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
