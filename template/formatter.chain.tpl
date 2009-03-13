<?php

	Class formatter/* CLASS NAME */ extends TextFormatter {
		private $_formatters;

		function __construct(&$parent) {
			parent::__construct($parent);

			/* FORMATTERS */

			if (!is_object($this->_Parent->FormatterManager)) {
				$this->_Parent->FormatterManager = new TextformatterManager($this->_Parent);
			}
		}
		
		function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.3',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		function run($string) {
			if (strlen(trim($string)) < 1) return $string;

			if (count($this->_formatters) < 1) return stripslashes($string);

			$result = $string;
			foreach ($this->_formatters as $id => $name) {
				$formatter = $this->_Parent->FormatterManager->create($id);
				$result = $formatter->run($result);
			}

			return stripslashes($result);
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		function ttf_form(&$form, &$page) {
			$formatters = $this->_Parent->FormatterManager->listAll();

			// Make formatters from $this->_formatters to be first and keep their order
			$temp = array();
			foreach ($this->_formatters as $id => $name) {
				$temp[$id] = $formaters[$id];
			}
			$formatters = array_merge($temp, $formatters);

			$subsection = new XMLElement('div');
			$subsection->setAttribute('class', 'subsection');
			$subsection->appendChild(new XMLElement('h3', __('Text formatters')));

			$ol = new XMLElement('ol');
			$ol->setAttribute('class', 'orderable subsection');

			foreach ($formatters as $id => $about) {
				if ($about['handle'] == '/* CLASS NAME */') continue;

				$li = new XMLElement('li');
				$li->setAttribute('class', 'unique template');

				$h4 = new XMLElement('h4', $about['name']);
				if ($about['templatedtextformatters-type']) {
					$i = new XMLElement('i');
					$i->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
					$h4->appendChild($i);
				}
				$li->appendChild($h4);

				$p = new XMLElement('p', $about['description']);
				$li->appendChild($p);

				$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));
				$ol->appendChild($li);

				if ($this->_formatters[$id]) {
					$li = new XMLElement('li');

					$h4 = new XMLElement('h4', $about['name']);
					if ($about['templatedtextformatters-type']) {
						$i = new XMLElement('i');
						$i->appendChild(Widget::Anchor(__('Edit'), URL.'/symphony/extension/templatedtextformatters/edit/'.$about['handle'], __('Edit this formatter')));
						$h4->appendChild($i);
					}
					$li->appendChild($h4);

					$p = new XMLElement('p', $about['description']);
					$li->appendChild($p);

					$li->appendChild(Widget::Input('fields[formatters]['.$id.']', $about['name'], 'hidden'));
					$ol->appendChild($li);
				}
			}
			
			$subsection->appendChild($ol);
			$form->appendChild($subsection);

			$p = new XMLElement('p', __('Formatters will be applied in order from top to bottom.'));
			$p->setAttribute('class', 'help');
			$form->appendChild($p);
		}

		// Hook called by TemplatedTextFormatters when saving formatter
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		function ttf_tokens() {
			$formatters = $this->_Parent->FormatterManager->listAll();

			$description = '';
			$code = '';
			// Reconstruct our current formatters array, so it's up-to-date when form is viewed right after save, without refresh/redirect
			$this->_formatters = array();
			if (is_array($_POST['fields']['formatters'])) {
				foreach ($_POST['fields']['formatters'] as $id => $name) {
					if (is_array($formatters[$id])) {
						$this->_formatters[$id] = $formatters[$id]['name'];
						$code .= '\''.$id.'\' => \''.preg_replace('/[^\w\s\.-_\&\;\#]/i', '', $this->_formatters[$id]).'\',';
					}
				}
				$description = __('Formatting text in following order: %s', array(implode(' &#8594; ', $this->_formatters)));
			}
			else {
				$description = __('None');
			}

			return array(
				'/*'.' DESCRIPTION */' => preg_replace('/[^\w\s\.-_\&\;\#\n]/i', '', $description),
				'/*'.' FORMATTERS */' => '$this->_formatters = array('.$code.');'
			);
		}
	}

