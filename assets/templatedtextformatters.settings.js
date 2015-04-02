
(function($) {

	$(document).ready(function() {

		$('.templatedtextformatter-duplicator').symphonyDuplicator({
			orderable: true,
			collapsible: (Symphony.Context.get('env')[0] !== 'new')
		});

	});

})(window.jQuery);