﻿<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<title><#Web_Title#> - Two-Way IPS</title>
<link rel="stylesheet" type="text/css" href="index_style.css"> 
<link rel="stylesheet" type="text/css" href="form_style.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/disk_functions.js"></script>
<script type="text/javascript" src="/form.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/js/Chart.js"></script>
<style>
#googleMap > div{
	border-radius: 10px;
}
</style>
<script>
<% get_AiDisk_status(); %>
var AM_to_cifs = get_share_management_status("cifs");  // Account Management for Network-Neighborhood
var AM_to_ftp = get_share_management_status("ftp");  // Account Management for FTP

var ctf_disable = '<% nvram_get("ctf_disable"); %>';
var ctf_fa_mode = '<% nvram_get("ctf_fa_mode"); %>';

function initial(){
	show_menu();

	if(document.form.wrs_protect_enable.value == '1' && document.form.wrs_vp_enable.value == '1'){
		vulnerability_check('1');
	}
	else{
		vulnerability_check('0');
	}

	getIPSCount();
	getEventTime();
	getIPSData("vp", "mac");
	var t = new Date();
	var timestamp = t.getTime();
	var date = timestamp.toString().substring(0, 10);
	getIPSChart("vp", date);
	getIPSDetailData("vp", "all");
}

function getEventTime(){
	var time = document.form.wrs_vp_t.value*1000;
	var vp_date = transferTimeFormat(time);
	$("#vp_time").html(vp_date);
}

function transferTimeFormat(time){
	if(time == 0){
		return '';
	}

	var t = new Date();
	t.setTime(time);
	var year = t.getFullYear();
	var month = t.getMonth() + 1;
	if(month < 10){
		month  = "0" + month;
	}
	
	var date = t.getDate();
	if(date < 10){
		date = "0" + date;
	}
	
	var hour = t.getHours();
	if(hour < 10){
		hour = "0" + hour;
	}
			
	var minute = t.getMinutes();
	if(minute < 10){
		minute = "0" + minute;
	}

	var date_format = "Since " + year + "/" + month + "/" + date + " " + hour + ":" + minute;
	return date_format;
}
var ips_count = 0;
function getIPSCount(){
	$.ajax({
		url: '/getAiProtectionEvent.asp',
		dataType: 'script',	
		error: function(xhr) {
			setTimeout("getIPSCount();", 1000);
		},
		success: function(response){
			var code = ""
			ips_count = event_count.vp_n;
			code += ips_count;
			code += '<span style="font-size: 16px;padding-left: 5px;">Hits</span>';
			$("#vp_count").html(code);
		}
	});
}

function getIPSData(type, event){
	$.ajax({
		url: '/getIPSEvent.asp?type=' + type + '&event=' + event,
		dataType: 'script',	
		error: function(xhr) {
			setTimeout("getIPSData('vp', event);", 1000);
		},
		success: function(response){
			if(data != ""){
				var data_array = JSON.parse(data);
				collectInfo(data_array);
			}
		}
	});
}

var info_bar = new Array();
var hit_count_all = 0;
function collectInfo(data){
	for(i=0;i<data.length;i++){
		var mac = data[i][0];
		var ip = ""
		var hit = data[i][1];
		var name = "";
		if(clientList[mac]){
			name = clientList[mac].name;
			ip = clientList[mac].ip;
		}
		else{
			name = mac;
		}

		hit_count_all += parseInt(hit);
		info_bar.push(mac);
		info_bar[mac] = new targetObject(ip, name, hit, mac);
	}

	generateBarTable();
}

function targetObject(ip, name, hit, mac){
	this.ip = ip;
	this.name = name;
	this.hit = hit;
	this.mac = mac;
}

function generateBarTable(){
	var code = '';
	for(i=0;i<info_bar.length;i++){
		var targetObj = info_bar[info_bar[i]];
		code += '<div style="margin:10px;">';
		code += '<div style="display:inline-block;width:130px;">'+ targetObj.name +'</div>';
		code += '<div style="display:inline-block;width:150px;">';
		if(hit_count_all == 0){
			var percent = 0;
		}
		else{
			var percent = parseInt((targetObj.hit/hit_count_all)*100);
			if(percent > 85)
				percent = 85;
		}

		code += '<div style="width:'+ percent +'%;background-color:#FC0;height:13px;border-radius:1px;display:inline-block;vertical-align:middle"></div>';
		code += '<div style="display:inline-block;padding-left:5px;">'+ targetObj.hit +'</div>';
		code += '</div>';
		code += '</div>';
	}

	if(code == ''){
		code += '<div style="font-size:16px;text-align:center;margin-top:70px;color:#FC0">No Event Detected</div>';		
	}

	$("#vp_bar_table").html(code);
}

function getIPSChart(type, date){
	$.ajax({
		 url: '/getIPSChart.asp?type=' + type + '&date='+ date,
		dataType: 'script',	
		error: function(xhr) {
			setTimeout("getIPSChart('vp', date);", 1000);
		},
		success: function(response){
			collectChart(data, date);
		}
	});
}

function collectChart(data, date){
	var timestamp = date*1000;
	var t = new Date(timestamp);
	t.setHours(23);
	t.setMinutes(59);
	t.setSeconds(59);
	var timestamp_new = t.getTime();
	var date_label = new Array();
	var month = "";
	var date = "";
	
	for(i=0;i<7;i++){
		var temp = new Date(timestamp_new);
		var date_format = "";
		month = temp.getMonth() + 1;
		date = temp.getDate();
		date_format = month + '/' + date;
		timestamp_new -= 86400000;
		date_label.unshift(date_format);
	}

	var high_array = new Array();
	var medium_array = new Array();
	var low_array =  new Array();
	hight_array = data[0];
	medium_array = data[1];
	low_array = data[2];

	drawLineChart(date_label, hight_array, medium_array, low_array);
}

function drawLineChart(date_label, high_array, medium_array, low_array){
	var lineChartData = {
		labels: date_label,
		datasets: [{
			fillColor: "rgba(255,255,255,0)",
			strokeColor: "#ED1C24",
			pointColor: "#ED1C24",
			pointHighlightFill: "#FFF",
			pointHighlightStroke: "#ED1C24",
			data: high_array
		}, {
			fillColor: "rgba(255,255,255,0)",
			strokeColor: "#FFE500",
			pointColor: "#FFE500",
			pointHighlightFill: "#FFF",
			pointHighlightStroke: "#FFE500",
			data: medium_array
		},
		/*{
			fillColor: "rgba(255,255,255,0)",
			strokeColor: "#00B0FF",
			pointColor: "#00B0FF",
			pointHighlightFill: "#FFF",
			pointHighlightStroke: "#00B0FF",
			data: ["48", "68", "56", "74", "59", "56", "33"]
		},*/
			{
			fillColor: "rgba(255,255,255,0)",
			strokeColor: "#59CA5E",
			pointColor: "#59CA5E",
			pointHighlightFill: "#FFF",
			pointHighlightStroke: "#59CA5E",
			data: low_array
		}]
	}


	var ctx = document.getElementById("canvas").getContext("2d");
	window.myLine = new Chart(ctx).Line(lineChartData, {
		responsive: true
	});
}

function getIPSDetailData(type, event){
	$.ajax({
		url: '/getIPSDetailEvent.asp?type=' + type + '&event=' + event,
		dataType: 'script',	
		error: function(xhr) {
			setTimeout("getIPSDetailData('vp', event);", 1000);
		},
		success: function(response){
			if(data != ""){
				var data_array = JSON.parse(data);
				generateDetailTable(data_array);
			}
		}
	});
}

function generateDetailTable(data_array){
	var direct_type = ["Client Device Infected", "External Attacks"];
	var code = '';
	code += '<div style="font-size:14px;font-weight:bold;border-bottom: 1px solid #797979">';
	code += '<div style="display:table-cell;width:70px;padding-right:5px;">Time</div>';
	code += '<div style="display:table-cell;width:50px;padding-right:5px;">Level</div>';
	code += '<div style="display:table-cell;width:140px;padding-right:5px;">Type</div>';
	
	code += '<div style="display:table-cell;width:130px;padding-right:5px;">Source</div>';
	code += '<div style="display:table-cell;width:130px;padding-right:5px;">Destination</div>';
	code += '<div style="display:table-cell;width:180px;padding-right:5px;">Security Alert</div>';
	code += '</div>';

	if(data_array == ""){
		code += '<div style="text-align:center;font-size:16px;color:#FC0;margin-top:90px;"><#IPConnection_VSList_Norule#></div>';
	}
	else{
		for(i=0;i<data_array.length;i++){
			code += '<div style="word-break:break-all;border-bottom: 1px solid #797979">';
			code += '<div style="display:table-cell;width:70px;height:30px;vertical-align:middle;padding-right:5px;">'+ data_array[i][0] +'</div>';
			var color = "";
			if(data_array[i][1] == "H"){
				color = '#ED1C24';
			}
			else if(data_array[i][1] == "M"){
				color = '#FFE500';
			}
			else{
				color = '#59CA5E';
			}
			code += '<div style="display:table-cell;width:50px;height:30px;vertical-align:middle;padding-right:5px;"><div style="width:15px;height:15px;background-color:'+color+';border-radius:50%;margin-left:10px;"></div></div>';
			code += '<div style="display:table-cell;width:140px;height:30px;vertical-align:middle;padding-right:5px;">'+ direct_type[data_array[i][5]] +'</div>';
			
			code += '<div style="display:table-cell;width:130px;height:30px;vertical-align:middle;padding-right:5px;">'+ data_array[i][2] +'</div>';
			code += '<div style="display:table-cell;width:130px;height:30px;vertical-align:middle;padding-right:5px;">'+ data_array[i][3] +'</div>';
			code += '<div style="display:table-cell;width:180px;height:30px;vertical-align:middle;padding-right:5px;">'+ data_array[i][4] +'</div>';
			code += '</div>';
		}
	}
	
	$("#detail_info_table").html(code);
}

function recount(){
	var t = new Date();
	var timestamp = t.getTime()

	if(document.form.wrs_vp_enable.value == "1"){												
		document.form.wrs_vp_t.value = timestamp.toString().substring(0, 10);
	}
	
	if(document.form.wrs_vp_enable.value == "1"){
		document.form.action_wait.value = "1";
		applyRule();
	}
}

function applyRule(){
	if(ctf_disable == 0 && ctf_fa_mode == 2){
		if(!confirm(Untranslated.ctf_fa_hint)){
			return false;
		}	
		else{
			document.form.action_script.value = "reboot";
			document.form.action_wait.value = "<% nvram_get("reboot_time"); %>";
		}	
	}

	showLoading();	
	document.form.submit();
}

function vulnerability_check(active){
	if(active == "1"){
		$("#bar_shade").css("display", "none");
		$("#chart_shade").css("display", "none");
		$("#info_shade").css("display", "none");
	}
	else{
		$("#bar_shade").css("display", "");
		$("#chart_shade").css("display", "");
		$("#info_shade").css("display", "");
	}
}

function recountHover(flag){
	if(flag == 1){
		$("#vulner_delete_icon").css("background","url('images/New_ui/recount_hover.svg')");
	}
	else{
		$("#vulner_delete_icon").css("background","url('images/New_ui/recount.svg')");
	}
}

function eraseDatabase(){
	document.form.action_script.value = 'reset_vp_db';
	document.form.action_wait.value = "1";
	applyRule();
}

function deleteHover(flag){
	if(flag == 1){
		$("#delete_icon").css("background","url('images/New_ui/delete_hover.svg')");
	}
	else{
		$("#delete_icon").css("background","url('images/New_ui/delete.svg')");
	}
}
</script>
</head>

<body onload="initial();" onunload="unload_body();" onselectstart="return false;">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<div id="agreement_panel" class="panel_folder" style="margin-top: -100px;"></div>
<div id="hiddenMask" class="popup_bg" style="z-index:999;">
	<table cellpadding="5" cellspacing="0" id="dr_sweet_advise" class="dr_sweet_advise" align="center"></table>
	<!--[if lte IE 6.5.]><script>alert("<#ALERT_TO_CHANGE_BROWSER#>");</script><![endif]-->
</div>
<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="AiProtection_IntrusionPreventionSystem.asp">
<input type="hidden" name="next_page" value="AiProtection_IntrusionPreventionSystem.asp">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="restart_wrs;restart_firewall">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>" disabled>
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="wrs_mals_enable" value="<% nvram_get("wrs_mals_enable"); %>">
<input type="hidden" name="wrs_cc_enable" value="<% nvram_get("wrs_cc_enable"); %>">
<input type="hidden" name="wrs_vp_enable" value="<% nvram_get("wrs_vp_enable"); %>">
<input type="hidden" name="wan0_upnp_enable" value="<% nvram_get("wan0_upnp_enable"); %>" disabled>
<input type="hidden" name="wan1_upnp_enable" value="<% nvram_get("wan1_upnp_enable"); %>" disabled>
<input type="hidden" name="misc_http_x" value="<% nvram_get("misc_http_x"); %>" disabled>
<input type="hidden" name="misc_ping_x" value="<% nvram_get("misc_ping_x"); %>" disabled>
<input type="hidden" name="dmz_ip" value="<% nvram_get("dmz_ip"); %>" disabled>
<input type="hidden" name="autofw_enable_x" value="<% nvram_get("autofw_enable_x"); %>" disabled>
<input type="hidden" name="vts_enable_x" value="<% nvram_get("vts_enable_x"); %>" disabled>
<input type="hidden" name="wps_enable" value="<% nvram_get("wps_enable"); %>" disabled>
<input type="hidden" name="wps_sta_pin" value="<% nvram_get("wps_sta_pin"); %>" disabled>
<input type="hidden" name="TM_EULA" value="<% nvram_get("TM_EULA"); %>">
<input type="hidden" name="PM_SMTP_SERVER" value="<% nvram_get("PM_SMTP_SERVER"); %>">
<input type="hidden" name="PM_SMTP_PORT" value="<% nvram_get("PM_SMTP_PORT"); %>">
<input type="hidden" name="PM_MY_EMAIL" value="<% nvram_get("PM_MY_EMAIL"); %>">
<input type="hidden" name="PM_SMTP_AUTH_USER" value="<% nvram_get("PM_SMTP_AUTH_USER"); %>">
<input type="hidden" name="PM_SMTP_AUTH_PASS" value="">
<input type="hidden" name="wrs_mail_bit" value="<% nvram_get("wrs_mail_bit"); %>">
<input type="hidden" name="st_ftp_force_mode" value="<% nvram_get("st_ftp_force_mode"); %>" disabled>
<input type="hidden" name="st_ftp_mode" value="<% nvram_get("st_ftp_mode"); %>" disabled>
<input type="hidden" name="st_samba_force_mode" value="<% nvram_get("st_samba_force_mode"); %>" disabled>
<input type="hidden" name="st_samba_mode" value="<% nvram_get("st_samba_mode"); %>" disabled>
<input type="hidden" name="wrs_vp_t" value="<% nvram_get("wrs_vp_t"); %>">
<input type="hidden" name="wrs_protect_enable" value="<% nvram_get("wrs_protect_enable"); %>">
<table class="content" align="center" cellpadding="0" cellspacing="0" >
	<tr>
		<td width="17">&nbsp;</td>		
		<td valign="top" width="202">				
			<div  id="mainMenu"></div>	
			<div  id="subMenu"></div>		
		</td>					
		<td valign="top">
			<div id="tabMenu" class="submenuBlock"></div>	
		<!--===================================Beginning of Main Content===========================================-->		
			<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0" >
				<tr>
					<td valign="top" >		
						<table width="730px" border="0" cellpadding="4" cellspacing="0" class="FormTitle" id="FormTitle">
							<tbody>
							<tr>
								<td style="background:#4D595D" valign="top">
									<div>&nbsp;</div>
									<div>
										<table width="730px">
											<tr>
												<td align="left">
													<span class="formfonttitle"><#AiProtection_title#> - Two-Way IPS</span>
												</td>
											</tr>
										</table>
									</div>									
									<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
									<div id="PC_desc">
										<table width="700px" style="margin-left:25px;">
											<tr>
												<td style="font-size:14px;">
													<div>Two-Way IPS (Intrusion Prevention System) prevents Spam or DDoS from attacking Internet device and blocks malicious incoming packets to protect router from network vulnerability attacks like Shellshocked, Heartbleed, Bitcoin mining and Ransomware attack ; And also detects suspicious outgoing packets to find infected device out, and then prevent from being enslaved by Botnets.</div>
												</td>
											</tr>									
										</table>
									</div>

									<!--=====Beginning of Main Content=====-->
									<div style="margin-top:5px;">
										<div style="display:table;margin: 10px 15px">

											<div style="display:table-cell;width:370px;height:350px;">
												<div style="display:table-row">
													<!--div style="display:inline-block;padding: 5px 0"><input id="mali_checkbox" type="checkbox" onclick="mali_check();"></div>
													<div style="display:inline-block;font-size:14px;vertical-align:bottom;padding: 5px 0" title="<#AiProtection_scan_desc#>"><#AiProtection_sites_blocking#></div-->
													<div style="font-size:16px;margin:0 0 5px 5px;text-align:center">Security Event</div>
												</div>
												<div id="vulner_table" style="background-color:#444f53;width:350px;height:340px;border-radius: 10px;display:table-cell;position:relative;">
													<div id="bar_shade" style="position:absolute;width:330px;height:330px;background-color:#505050;opacity:0.6;margin:5px;display:none"></div>
													<div>
														<div style="display:table-cell;width:50px;padding: 10px;">
															<div style="width:35px;height:35px;background:url('images/New_ui/IPS.svg');margin: 0 auto;"></div>

														</div>	
														<div style="display:table-cell;width:200px;padding: 10px;vertical-align:middle;text-align:center;">
															<div id="vp_count" style="margin: 0 auto;font-size:26px;font-weight:bold;color:#FC0"></div>
															<div id="vp_time" style="margin: 5px  auto 0;"></div>
														</div>	
														<div style="display:table-cell;width:50px;padding: 10px;">
															<div id="vulner_delete_icon" style="width:32px;height:32px;margin: 0 auto;cursor:pointer;background:url('images/New_ui/recount.svg');" onclick="recount();" onmouseover="recountHover('1')" onmouseout="recountHover('0')"></div>
														</div>	
													</div>
													<div style="height:240px;margin-top:0px;">
														<div style="text-align:center;font-size:16px;">Top Client</div>
														<div id="vp_bar_table" style="height:235px;margin: 0 10px;border-radius:10px;overflow:auto"></div>
													</div>
												</div>
											</div>

											<div style="display:table-cell;width:370px;height:350px;padding-left:10px;">
												<div style="font-size:16px;margin:0 0 5px 5px;text-align:center;">Severity Level</div>

												<!-- Line Chart -Block-->
												<div style="background-color:#444f53;width:350px;height:340px;border-radius: 10px;display:table-cell;padding-left:10px;position:relative">
													<div id="chart_shade" style="position:absolute;width:350px;height:330px;background-color:#505050;opacity:0.6;margin:5px 0 5px -5px;display:none"></div>
													<div>
														<div style="display:inline-block;margin:5px 10px">Hits</div>
														<div style="display:inline-block;margin:5px 10px">
															<div style="display:inline-block"><div style="width:10px;height:10px;border-radius:50%;background:#ED1C24"></div></div>
															<div style="display:inline-block">High</div>
														</div>
														<div style="display:inline-block;margin:5px 10px">
															<div style="display:inline-block"><div style="width:10px;height:10px;border-radius:50%;background:#FFE500"></div></div>
															<div style="display:inline-block">Medium</div>
														</div>
														<div style="display:inline-block;margin:5px 10px">
															<div style="display:inline-block"><div style="width:10px;height:10px;border-radius:50%;background:#59CA5E"></div></div>
															<div style="display:inline-block">Low</div>
														</div>		
													</div>			
													<div style="width:90%">
														<div>
															<canvas id="canvas"></canvas>
														</div>
													</div>	

												</div>

												<!-- End Line Chart Block -->

											</div>
										</div>


										<!--div style="margin: 10px auto;width:720px;height:500px;">
											<div id="googleMap" style="height:100%;">

											</div>
										</div-->
										<div>
											<div style="text-align:center;font-size:16px;">Event Details</div>
											<div style="float:right;margin:-20px 30px 0 0"><div id="delete_icon" style="width:25px;height:25px;background:url('images/New_ui/delete.svg')" onclick="eraseDatabase();" onmouseover="deleteHover('1')" onmouseout="deleteHover('0')"></div></div>
										</div>
										<div style="margin: 10px auto;width:720px;height:500px;background:#444f53;border-radius:10px;position:relative;overflow:auto">
											<div id="info_shade" style="position:absolute;width:710px;height:490px;background-color:#505050;opacity:0.6;margin:5px;display:none"></div>
											<div id="detail_info_table" style="padding: 10px 15px;">
												<div style="font-size:14px;font-weight:bold;border-bottom: 1px solid #797979">
													<div style="display:table-cell;width:110px;padding-right:5px;">Time</div>
													<div style="display:table-cell;width:50px;padding-right:5px;">Level</div>
													<div style="display:table-cell;width:150px;padding-right:5px;">Source</div>
													<div style="display:table-cell;width:150px;padding-right:5px;">Destination</div>
													<div style="display:table-cell;width:220px;padding-right:5px;">Security Alert</div>
												</div>
												<!--div style="word-break:break-all;border-bottom: 1px solid #797979">
													<div style="display:table-cell;width:110px;height:30px;vertical-align:middle;padding-right:5px;">2016/08/15 11:25</div>
													<div style="display:table-cell;width:50px;height:30px;vertical-align:middle;padding-right:5px;"><div style="width:15px;height:15px;background-color:#F9BA63;border-radius:50%;margin-left:10px;"></div></div>
													<div style="display:table-cell;width:150px;height:30px;vertical-align:middle;padding-right:5px;">192.168.111.222</div>
													<div style="display:table-cell;width:150px;height:30px;vertical-align:middle;padding-right:5px;">device name or ip or mac</div>
													<div style="display:table-cell;width:220px;height:30px;vertical-align:middle;padding-right:5px;">write something here</div>
												</div-->												
											</div>
										</div>
									</div>
									<div style="width:135px;height:55px;margin: 10px 0 0 600px;background-image:url('images/New_ui/tm_logo_power.png');"></div>
								</td>
							</tr>
							</tbody>	
						</table>
					</td>         
				</tr>
			</table>				
		<!--===================================Ending of Main Content===========================================-->		
		</td>		
		<td width="10" align="center" valign="top">&nbsp;</td>
	</tr>
</table>
<div id="footer"></div>
</form>
</body>
</html>