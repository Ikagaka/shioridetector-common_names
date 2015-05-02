shiori_by_dll_name =
	'satori.dll': 'satori'
	'yaya.dll': 'yaya'
	'aya5.dll': 'aya5'
	'aya.dll': 'aya'
	'misaka.dll': 'misaka'
	'akari.dll': 'akari'
	'main.azr': 'akari'
	'ese-shiori.dll': 'ese_shiori'
	'eseai.ini': 'ese_shiori'
	'pixy.dll': 'pixy'
	'psyche.dll': 'psyche_system'
	'init.vsc': 'scheme_shiori'
	'hitomi.dll': 'hitomi'
	'yuhna.dll': 'yuhna'
	'mae_corpus.txt': 'mae'
	'touri.dll': 'touri'
	'shino.dll': 'shino'
	'nasino.dll': 'nasino'
	'nasino.ini': 'nasino'
	'rishu_proxy.dll': 'rishu'
	'rishu_remote.pl': 'rishu'
	'hisui.dll': 'hisui'
	'hisuiconf.xml': 'hisui'

stat_detect = (fs, file_path, shiori_name) ->
	new Promise (resolve, reject) ->
		fs.stat file_path, (err, stat) ->
			if err? then reject() else resolve shiori_name

resolve_pseudo_shiori = (resolve, reject, fs, shiori) ->
	if shiori?
		try
			resolve new shiori(fs)
		catch error
			reject error
	else
		reject new Error "SHIORI subsystem '#{shiori_name}' is detected but pseudo SHIORI subsystem for that is not supported."

detector = (fs, dirpath, shiories) ->
	new Promise (resolve, reject) ->
		fs.readFile dirpath + 'descript.txt', {encoding: 'utf8'}, (err, data) ->
			if !err? and result = /^\s*shiori\s*,\s*(.*)\s*$/i.exec data
				shiori_path = result[1]
			else
				shiori_path = 'shiori.dll'
			shiori_name = shiori_by_dll_name[shiori_path]
			if shiori_name?
				shiori = shiories[shiori_name]
				resolve_pseudo_shiori(resolve, reject, fs, shiori)
			else
				detect_promise = stat_detect(fs, dirpath + 'kawarirc.kis', 'kawari')
				.catch -> stat_detect(fs, dirpath + 'kawari.ini', 'kawari7') # no kis and ini
				for file_path, shiori_name of shiori_by_dll_name
					detect_promise = ((file_path, shiori_name) ->
						detect_promise.catch -> stat_detect(fs, dirpath + file_path, shiori_name)
					)(file_path, shiori_name)
				detect_promise.then (shiori_name) ->
					shiori = shiories[shiori_name]
					resolve_pseudo_shiori(resolve, reject, fs, shiori)
				, (error) ->
					resolve null

if module?.exports?
	module.exports = detector
else
	if @ShioriLoader?.shiori_detectors?
		ShioriLoader.shiori_detectors.push detector
	else
		throw "load ShioriLoader first"
