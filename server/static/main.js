$(function() {
    function replaceBody() {
        $.ajax("/?body_only=true").success(function(r) {
            $("body").html(r);
        });

        setTimeout(replaceBody, 2000);
    }

    setTimeout(replaceBody, 2000);
});
