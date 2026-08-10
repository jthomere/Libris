//
//  SampleData.swift
//  Libris
//
//  A small set of well-known books the user can load into an empty library
//  from the empty-state "Load Sample Books" button in ContentView. Safe to
//  delete if you don't want sample data.
//

import Foundation

enum SampleData {
    /// Freshly-built (not-yet-inserted) sample books, spanning every status.
    static func makeBooks() -> [Book] {
        [
            Book(
                title: "Dune",
                author: "Frank Herbert",
                bookDescription: "On the desert planet Arrakis, a young heir becomes the fulcrum of a galactic struggle over the universe's most valuable substance.",
                genre: "Science Fiction",
                rating: 5,
                goodreadsURL: "https://www.goodreads.com/book/show/44767458-dune",
                amazonURL: "https://www.amazon.com/dp/0441172717",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg",
                note: "The Villeneuve films sent me back to the source.",
                tags: ["Staff Pick", "Bestseller"],
                status: .toRead
            ),
            Book(
                title: "The Left Hand of Darkness",
                author: "Ursula K. Le Guin",
                bookDescription: "An envoy to an icebound world must navigate a society without fixed gender to broker an interstellar alliance.",
                genre: "Science Fiction",
                rating: 5,
                goodreadsURL: "https://www.goodreads.com/book/show/18423.The_Left_Hand_of_Darkness",
                amazonURL: "https://www.amazon.com/dp/0441478123",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780441478125-L.jpg",
                note: "Still the high-water mark for the genre.",
                tags: ["Award Winner"],
                status: .read
            ),
            Book(
                title: "The Name of the Wind",
                author: "Patrick Rothfuss",
                bookDescription: "A gifted young man recounts his rise from orphaned street child to the most notorious wizard of his age.",
                genre: "Fantasy",
                rating: 4,
                goodreadsURL: "https://www.goodreads.com/book/show/186074.The_Name_of_the_Wind",
                amazonURL: "https://www.amazon.com/dp/0756404746",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780756404741-L.jpg",
                note: "Gorgeous prose. Still waiting on book three.",
                tags: ["Bestseller"],
                status: .read
            ),
            Book(
                title: "Project Hail Mary",
                author: "Andy Weir",
                bookDescription: "A lone astronaut wakes with no memory aboard a ship that is humanity's last hope against an extinction-level threat.",
                genre: "Science Fiction",
                rating: 5,
                goodreadsURL: "https://www.goodreads.com/book/show/54493401-project-hail-mary",
                amazonURL: "https://www.amazon.com/dp/0593135202",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780593135204-L.jpg",
                note: "Recommended by a friend — moving it up the queue.",
                tags: ["Staff Pick"],
                status: .toRead
            ),
            Book(
                title: "Educated",
                author: "Tara Westover",
                bookDescription: "A memoir of growing up in a survivalist family and the author's improbable journey to a Cambridge PhD.",
                genre: "Memoir",
                rating: 4,
                goodreadsURL: "https://www.goodreads.com/book/show/35133922-educated",
                amazonURL: "https://www.amazon.com/dp/0399590501",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780399590504-L.jpg",
                note: "Book club pick from last spring.",
                tags: ["Book Club"],
                status: .read
            ),
            Book(
                title: "The Midnight Library",
                author: "Matt Haig",
                bookDescription: "Between life and death lies a library where each book is a life you could have lived.",
                genre: "Fiction",
                rating: 3,
                goodreadsURL: "https://www.goodreads.com/book/show/52578297-the-midnight-library",
                amazonURL: "https://www.amazon.com/dp/0525559477",
                coverImageURL: "https://covers.openlibrary.org/b/isbn/9780525559474-L.jpg",
                note: "Didn't land for me — flagging to pass along.",
                tags: [],
                status: .toRemove
            )
        ]
    }
}
