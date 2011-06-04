<?php

	Class extension_templatedtextformatters extends Extension {
	
		public function about() {
			return array('name' => __('Templated Text Formatters'),
						 'version' => '1.7',
						 'release-date' => '2011-06-04',
						 'author' => array('name' => 'Marcin Konicki',
										   'website' => 'http://ahwayakchih.neoni.net',
										   'email' => 'ahwayakchih@neoni.net'),
						 'description' => __('Allows to chain text formatters into as if they were one text formatter and/or create new text formatters based on installed templates. For example You can chain Markdown and BBCode text formatters, so text will be formatted by Markdown first and than by BBCode.')
				 		);
		}

		public function install() {
			$result = true;

			if (!file_exists(TEXTFORMATTERS)) {
				$result = General::realiseDirectory(TEXTFORMATTERS, Symphony::Configuration()->get('write_mode', 'directory'));
			}

			return $result;
		}

		public function uninstall() {
			// TODO: remove all created formatters?
			return true;
		}

		public function update($previousVersion=false) {
			if (!$this->install()) return false;

			if (version_compare($previousVersion, '1.4', '<')) {
				$this->upgrade_1_3();
			}

			return true;
		}

		public function enable() {
			return $this->install();
		}

		public function fetchNavigation() {
			return array(
				array(
					'location' => __('Blueprints'),
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
			static $result;
			if (is_array($result)) return $result;

			$extensions = Symphony::ExtensionManager()->listInstalledHandles();
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

		public function needsUpdate($name, $type) {
			$types = $this->listTypes();
			$file = TEXTFORMATTERS . "/formatter.{$name}.php";
			if (!$types[$type] || !file_exists($file) || filemtime($types[$type]['path']."/formatter.{$type}.tpl") <= filemtime($file)) return false;

			return true;
		}

		private function upgrade_1_3() {
			$types = $this->listTypes();
			$formatters = $this->listAll();
			$aboutDriver = $this->about();

			foreach (array_keys($types) as $type) {
				$types[$type]['code'] = file_get_contents($types[$type]['path'].'/formatter.'.$type.'.tpl');
				if (preg_match('/public\s*function\s*ttf_tokens\s*\([^\)]*\)\s*(\{(?:[^\{\}]+|(?1))*\})/', $types[$type]['code'], $m)) {
					$types[$type]['ttf_tokens_code'] = $m[0];
				}
			}

			include_once(TOOLKIT . '/class.textformattermanager.php');
			foreach ($formatters as $id => $dummy) {
				$file = TEXTFORMATTERS . "/formatter.{$id}.php";
				$data = file_get_contents($file);

				if (!preg_match('/public\s*function\s*ttf_tokens\s*\([^\)]*\)\s*(\{(?:[^\{\}]+|(?1))*\})/', $data, $m)) continue;

				$code = $m[0];
				if (!preg_match('/\'templatedtextformatters-type\'\s*=>\s*\'([^\']+)\'/', $data, $m)) continue;

				$type = $m[1];
				if (!$types[$type] || !$types[$type]['ttf_tokens_code']) continue;

				$data = str_replace($code, $types[$type]['ttf_tokens_code'], $data);
				if (!General::writeFile($file, $data, Symphony::Configuration()->get('write_mode', 'file'))) continue;

				include_once($file);
				$classname = "formatter{$id}";
				$old = new $classname($this->_Parent);

				$about = $old->about();
				$tokens = array(
					'___'.$type.'/* CLASS NAME */' => $id,
					'/* NAME */' => preg_replace('/[^\w\s\.-_\&\;]/i', '', trim($about['name'])),
					'/* AUTHOR NAME */' => $about['author']['name'],
					'/* AUTHOR WEBSITE */' => $about['author']['website'],
					'/* AUTHOR EMAIL */' => $about['author']['email'],
					'/* RELEASE DATE */' => DateTimeObj::getGMT('c'), //date('Y-m-d', $oDate->get(true, false)),
					'/* TEMPLATEDTEXTFORMATTERS VERSION */' => $aboutDriver['version'],
					'/* TEMPLATEDTEXTFORMATTERS TYPE */' => $type,
				);

				if (method_exists($old, 'ttf_tokens')) {
					$tokens = array_merge($tokens, $old->ttf_tokens(false));
				}

				$code = str_replace(array_keys($tokens), $tokens, $types[$type]['code']);
				$code = str_replace('/* CLASS NAME */', $classname, $code);
				General::writeFile($file, $code, Symphony::Configuration()->get('write_mode', 'file'));
			}
		}
	}

