# Bookshelf

A personal project to fix a minor annoyance that I've had for a while but should you have the same annoyance and find this useful, then the code is here under an MIT License so make use of it as you will. It is very much still under development so it may change beyond all recognition or, if I really lose my temper with it, disappear without warning.

### Backstory

Over the past few years, through purchases and give-aways from various online stores and event promos, I have found myself to be the proud owner of a big pile of e-books that live outside of Amazon's Kindle or Apple's iBooks platforms. A big old jumble of files on my computer. I find the file viewer less than helpful in keeping things organised and have occasionally, and I know I'm not alone in this as I've seen others on Twitter do the same, bought the same book twice having not realised I already owned it until the Save As dialogue asked if I wanted to replace an older file of the same name (uh oh!).

### Concept

So this is me - hopefully with some help from my friends - flailingly attempting to write a command line script (the format of which has yet to be decided, I'm going to try stuff and see what works) that generates a flat HTML page or 3 to help me keep track of my book collection. I'll warn you now, the conventions are going to be entirely to my taste and will pander to the idiosyncratic file structure that I've developed while trying to keep the file sprawl in check. We're deep in "scratch your own itch" territory here.

Oh and the use of flat files (CSS and Javascript welcome, just no backend stuff) is a deliberate trick to allow the resulting file(s) to run right out of the filesystem rather than needing a webserver running in the background to quickly look something up. This poses an obvious problem for any future search implementations (and opens up the potential to accidentally lock this in to a *nix-like system by cheating and invoking grep) but we can burn those bridges when we get to them. Maybe we'll have enough metadata in the page for Javascript to be able to save us by that point, you never know.

## File structure

The basic current file structure inside my `bookshelf` folder, which has changed slightly since starting the project, looks a bit like this (but longer, much, much longer)

    ├── A Little Riak Book
    │   ├── _meta
    │   │   ├── cover.jpg
    │   │   └── info.js
    │   ├── riaklil-en.epub
    │   ├── riaklil-en.mobi
    │   └── riaklil-en.pdf
    ├── The Little MongoDB Book
    │   ├── Little_MongoDB_Book.pdf
    │   └── _meta
    │       ├── cover.jpg
    │       └── info.js

As you can see, each book has it's own named folder containing the book file itself - or files plural if I own it in more than one format - and a `_meta` folder containing a JSON file (currently generated by hand) containing stuff like - sorry to be so handwavy here, but this bit's very much under construction - the book's full title, the publisher, the authors (they're mostly tech books so having an array of authors seems logical), the ISBN (if it has one, some freebie "use my product!" books don't), the publisher, a notes field that's currently only used to highlight which edition/printing of *Agile Web Development with Rails* covers which Rails version but could be more generally useful. And a cover image, currently 160px high with a varying width as it turns out, as I should have been able to spot right away by turning round and looking at my actual book shelf, not all books are the same size (or even in the same aspect ratio), but I **hate** the screen jumping around as it loads so as it's my dictatorship, I've arbitrarily declared 160px high to be a standard.


### A complication of file structures

It also turns out that in some cases I own more than one edition/printing/version/whatevs of the same book. A recent addition to the file structure spec, therefore makes it look something like this...

    ├── Agile Web Development with Rails
    │   ├── 4th Edition v3.0
    │   │   ├── _meta
    │   │   │   ├── cover.jpg
    │   │   │   └── info.js
    │   │   ├── book.epub
    │   │   ├── book.mobi
    │   ├── 4th Edition v3.1
    │   │   ├── _meta
    │   │   │   ├── cover.jpg
    │   │   │   └── info.js
    │   │   ├── book.mobi
    │   │   └── book.pdf

Which allows me to a) group them in a way that looks reasonably sensible to me (and, as I said before - my files, my rules) and b) that stops the file list from getting cluttered up with "Book A v1", "Book A v2" and so on.


## Languages and other stories

***Why Ruby?*** Because I'm lazy and have a day job and had originally thought I could do this "quickly" (hah! - this is a bigger joke to friends I've shared a subset of the file structure with as they get to see the timestamps) so picked up the language that I know the best, regardless of whether or not it's the right tool for the job. It's a tool and it's handy and as I'm still working out what the job really is then it's as good a tool as any.

***Why not a shell script?*** Too easy for me to make something that will only run on my actual machine, or at least only on a Mac. Plus if you do find a machine it will run on then the script would have fairly unlimited powers to do whatever it wanted when you run it, so no from that point of view as well.

***Why not pure Javascript?*** Well, that's what I originally imagined - a (relatively) small set of files that you dropped into your bookshelf folder and load up in your browser and ... hey presto you could see all your books and start messing about re-ordering them and looking through them. But then there was all the unpleasantness about sandboxes and trusting filesystems so... no to all of that. Maybe it could be fine with a bucketload of extra effort but if I gave the file away to anyone to use on their machine, they'd need to give my - by then probably eye-wateringly complicated - little gadget a level of trust on their system which wouldn't be a good idea for anyone and could cause myriad unforeseen side-effects by encouraging people to lower their browser's defences and... Suddenly it looks better to use a generator to pre-bake stuff instead. And Grunt.js gives me a headache (as well as being hard for "non-technical" people to work with).

## How do I make it go?

Ok, sorry, probably should have done this bit sooner...

1. Git clone your own copy of the repository
2. Drop `assets` and `bin` directories and the `Rakefile` into the top level directory of [a folder structure that's arranged a bit like mine](#file-structure) and has lots of books in it<sup>[&dagger;](#footnote-1)</sup>
3. From the command line, navigate to the folder you copied the files into and run:
    <pre>rake generate_index_file shelf="."</pre>
4. Load the resulting index.html into your favourite browser

Tip: vary the value of `shelf=` to change the target directory for the script

* * *

<a name="footnote-1"></a>
<sup>&dagger;</sup>If you don't have a folder with lots of books in it<sup>[&Dagger;](#footnote-2)</sup>, you may have come to the wrong place

<a name="footnote-2"></a>
<sup>&Dagger;</sup>If you would like a folder with lots of books in it, may I suggest [Project Gutenberg](http://www.gutenberg.org) as a good starting point

