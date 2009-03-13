<?php
	Class extension_templatedtextformatters extends Extension {
	
		public function about() {
			return array('name' => __('Templated Text Formatters'),
						 'version' => '1.4',
						 'release-date' => '2009-03-13',
						 'author' => array('name' => 'Marcin Konicki',
										   'website' => 'http://ahwayakchih.neoni.net',
										   'email' => 'ahwayakchih@neoni.net'),
						 'description' => __('Allows to chain text formatters into one text formatter or crate new text formatters based on installed templates. For example You can chain Markdown and BBCode text formatters, so text will be formatted by Markdown first and than by BBCode.')
				 		);
		}

		function install() {
			$result = true;

			if (!file_exists(TEXTFORMATTERS)) {
				$result = General::realiseDirectory(TEXTFORMATTERS, $this->_Parent->Configuration->get('write_mode', 'directory'));
			}

			return $result;
		}

		function uninstall() {
			// TODO: remove all created formatters?
			return true;
		}

		function update($previousVersion=false) {
			return $this->install();
		}

		function enable() {
			return $this->install();
		}

		public function fetchNavigation() {
			return array(
				array(
					'location' => 200,
					'name' => __('Templated Text Formatters'),
					'limit'	=> 'developer',
				),
			);
		}

		public function listAll() {
			$structure = General::listStructure(TEXTFORMATTERS, '/formatter.ttf_[\\w-]+.php/', false, 'ASC', TEXTFORMATTERS);

			$result = array();
			if (is_array($structure['filelist']) && !empty($structure['filelist'])) {
				foreach ($structure['filelist'] as $f) {
					$handle = preg_replace(array('/^formatter./i', '/.php$/i'), '', $f);
					$result[$handle] = array();
				}
			}

			return $result;
		}

		public function listTypes() {
			$extensions = $this->_Parent->ExtensionManager->listInstalledHandles();
			if (!is_array($extensions) || empty($extensions)) return array();

			$result = array();
			foreach ($extensions as $e) {
				$path = EXTENSIONS . "/{$e}/template";
				if (!is_dir($path)) continue;

				$structure = General::listStructure($path, '/^formatter.[\\w-]+.tpl$/', false, 'ASC', $path);
				if (is_array($structure['filelist']) && !empty($structure['filelist'])) {
					foreach ($structure['filelist'] as $t) {
						$type = preg_replace(array('/^formatter./i', '/.tpl$/i'), '', $t);
						$result[$type] = array('path' => $path);
					}
				}
			}

			return $result;
		}
	}

