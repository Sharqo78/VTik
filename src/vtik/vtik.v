module vtik

import net.http
import x.json2
import os

struct VTik {
	m_str_tag string = 'VTik'
mut:
	m_str_title     string
	m_str_base_url  string
	m_str_json_url  string
	m_str_video_url string
}

pub fn new(str_url string) ?VTik {
	mut vtik := VTik{
		m_str_base_url: str_url
	}

	if vtik.is_url_shortened() {
		vtik.shortened_to_long_url()?
	}

	vtik.get_json_url()
	vtik.m_str_video_url = vtik.get_video_infos()?

	return vtik
}

fn (vtik VTik) is_url_shortened() bool {
	return vtik.m_str_base_url.contains('vm.tiktok.com')
}

fn (mut vtik VTik) shortened_to_long_url() ? {
	println('$vtik.m_str_tag URL is shortened, unshortening it')

	req := http.Request{
		url: vtik.m_str_base_url
		method: http.Method.get
		allow_redirect: false
	}

	res := req.do()?

	vtik.m_str_base_url = res.header.get_custom('Location')?
}

fn (mut vtik VTik) get_json_url() {
	println('$vtik.m_str_tag Getting JSON data URL')

	str_tokens := vtik.m_str_base_url.split('/')
	str_username := str_tokens[3]
	str_id := str_tokens[5].split('?')[0]

	vtik.m_str_json_url = 'https://www.tiktok.com/node/share/video/$str_username/$str_id'

	println(vtik.m_str_json_url)
}

pub fn (mut vtik VTik) get_video_infos() ?string {
	println('$vtik.m_str_tag Getting raw video URL and title')

	res := http.get(vtik.m_str_json_url)?
	str_raw_json := res.body

	video_json := json2.raw_decode(str_raw_json)?
	video_map := video_json.as_map()

	mut video_any := video_map['itemInfo']?
	video_any = video_any.as_map()['itemStruct']?
	video_any = video_any.as_map()['video']?

	str_video_url := video_any.as_map()['downloadAddr']?.str()

	vtik.m_str_title = video_map['seoProps']?.as_map()['metaParams']?.as_map()['title']?.str()
	return str_video_url
}

pub fn (vtik VTik) download_video(path string) ? {
	mut path_corrected := path

	if path_corrected.ends_with('/') == false {
		path_corrected += '/'
	}
	complete_path := path_corrected + '[vtik] ' + vtik.m_str_title + '.mp4'
	println('$vtik.m_str_tag Downloading video -> $complete_path')

	res := http.get(vtik.m_str_video_url)?
	os.write_file_array(complete_path, res.body.bytes())?

	println('$vtik.m_str_tag Done !')
}
