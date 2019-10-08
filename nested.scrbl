#lang scribble/manual
@(require scribble/minted)

@minted["md"]{
## Hello world
<script type="racket">
@minted["racket"]{#lang racket
(displayln "Hello World")
}
</script>
}
