+++
date = "2015-11-23T11:14:28-05:00"
title = "lunr"
+++

# hugo-lunr
## Generate lunr.js index files from Hugo static sites

## Installation

Install the hugo-lunr utility via [npm](http://npmjs.org/):

```
$ npm install hugo-lunr
```

## How to use hugo-lunr CLI
```
$ hugo-lunr -i \"content/**\" -o public/lunr.js
```


## Code example
```javascript
var hugolunr = require('hugo-lunr');
hugolunr.index();
var html = fs.readFileSync('./test/businesscard.html', 'utf8');
var options = { format: 'Letter' };

pdf.create(html, options).toFile('./businesscard.pdf', function(err, res) {
  if (err) return console.log(err);
  console.log(res); // { filename: '/app/businesscard.pdf' }
});
```

## Command-line example

