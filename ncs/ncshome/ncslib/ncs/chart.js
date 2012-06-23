var google_chart = "http://chart.apis.google.com/chart?"
function create_chartmap(chartholder,mapname){
	var data = {"chartshape":[{"name":"axis0_0","type":"RECT","coords":[28,167,31,175]},{"name":"axis0_1","type":"RECT","coords":[42,167,48,175]},{"name":"axis0_2","type":"RECT","coords":[57,166,63,175]},{"name":"axis0_3","type":"RECT","coords":[72,167,78,175]},{"name":"axis0_4","type":"RECT","coords":[87,166,93,175]},{"name":"axis0_5","type":"RECT","coords":[102,166,108,175]},{"name":"axis0_6","type":"RECT","coords":[117,167,123,175]},{"name":"axis0_7","type":"RECT","coords":[132,166,138,175]},{"name":"axis0_8","type":"RECT","coords":[147,166,153,175]},{"name":"axis0_9","type":"RECT","coords":[159,166,170,175]},{"name":"axis0_10","type":"RECT","coords":[175,167,184,175]},{"name":"axis0_11","type":"RECT","coords":[189,167,200,175]},{"name":"axis0_12","type":"RECT","coords":[204,166,215,175]},{"name":"axis0_13","type":"RECT","coords":[219,167,230,175]},{"name":"axis0_14","type":"RECT","coords":[234,166,245,175]},{"name":"axis0_15","type":"RECT","coords":[249,166,260,175]},{"name":"axis0_16","type":"RECT","coords":[264,167,275,175]},{"name":"axis0_17","type":"RECT","coords":[279,166,290,175]},{"name":"axis0_18","type":"RECT","coords":[294,166,305,175]},{"name":"axis0_19","type":"RECT","coords":[309,166,321,175]},{"name":"axis0_20","type":"RECT","coords":[325,167,335,175]},{"name":"axis0_21","type":"RECT","coords":[339,167,351,175]},{"name":"axis0_22","type":"RECT","coords":[354,166,366,175]},{"name":"axis0_23","type":"RECT","coords":[369,167,381,175]},{"name":"axis0_24","type":"RECT","coords":[384,166,396,175]},{"name":"axis0_25","type":"RECT","coords":[399,166,411,175]},{"name":"axis0_26","type":"RECT","coords":[414,167,426,175]},{"name":"axis0_27","type":"RECT","coords":[429,166,441,175]},{"name":"axis0_28","type":"RECT","coords":[444,166,456,175]},{"name":"axis0_29","type":"RECT","coords":[459,166,471,175]},{"name":"axis0_30","type":"RECT","coords":[475,166,485,175]},{"name":"axis0_31","type":"RECT","coords":[489,166,501,175]},{"name":"axis3_0","type":"RECT","coords":[250,185,274,194]},{"name":"axis1_0","type":"RECT","coords":[10,156,16,164]},{"name":"axis1_1","type":"RECT","coords":[1,125,16,133]},{"name":"axis1_2","type":"RECT","coords":[1,94,16,102]},{"name":"axis1_3","type":"RECT","coords":[1,62,16,71]},{"name":"axis1_4","type":"RECT","coords":[1,31,16,40]},{"name":"axis1_5","type":"RECT","coords":[12,0,15,9]},{"name":"axis2_0","type":"RECT","coords":[509,156,514,164]},{"name":"axis2_1","type":"RECT","coords":[509,130,527,138]},{"name":"axis2_2","type":"RECT","coords":[509,104,527,112]},{"name":"axis2_3","type":"RECT","coords":[509,78,527,86]},{"name":"axis2_4","type":"RECT","coords":[509,52,527,60]},{"name":"axis2_5","type":"RECT","coords":[508,26,532,34]},{"name":"axis2_6","type":"RECT","coords":[508,0,532,8]},{"name":"legend0","type":"RECT","coords":[543,58,555,70]},{"name":"legend1","type":"RECT","coords":[543,76,555,88]},{"name":"legend2","type":"RECT","coords":[543,94,555,106]},{"name":"bar0_0","type":"RECT","coords":[26,160,36,4]},{"name":"bar0_1","type":"RECT","coords":[41,160,51,95]},{"name":"bar1_1","type":"RECT","coords":[41,95,51,4]},{"name":"bar0_2","type":"RECT","coords":[56,160,66,51]},{"name":"bar1_2","type":"RECT","coords":[56,51,66,4]},{"name":"bar2_3","type":"RECT","coords":[71,160,81,4]},{"name":"bar2_4","type":"RECT","coords":[86,160,96,4]},{"name":"bar0_5","type":"RECT","coords":[101,160,111,61]},{"name":"bar1_5","type":"RECT","coords":[101,61,111,4]},{"name":"bar0_6","type":"RECT","coords":[116,160,126,150]},{"name":"bar1_6","type":"RECT","coords":[116,150,126,4]},{"name":"bar0_7","type":"RECT","coords":[131,160,141,55]},{"name":"bar1_7","type":"RECT","coords":[131,55,141,4]},{"name":"bar0_8","type":"RECT","coords":[146,160,156,55]},{"name":"bar1_8","type":"RECT","coords":[146,55,156,4]},{"name":"bar0_9","type":"RECT","coords":[161,160,171,55]},{"name":"bar1_9","type":"RECT","coords":[161,55,171,4]},{"name":"bar0_10","type":"RECT","coords":[176,160,186,55]},{"name":"bar1_10","type":"RECT","coords":[176,55,186,4]},{"name":"bar2_11","type":"RECT","coords":[191,160,201,4]},{"name":"bar2_12","type":"RECT","coords":[206,160,216,4]},{"name":"bar2_13","type":"RECT","coords":[221,160,231,4]},{"name":"bar2_14","type":"RECT","coords":[236,160,246,4]},{"name":"bar2_15","type":"RECT","coords":[251,160,261,4]},{"name":"bar2_16","type":"RECT","coords":[266,160,276,4]},{"name":"bar2_17","type":"RECT","coords":[281,160,291,4]},{"name":"bar2_18","type":"RECT","coords":[296,160,306,4]},{"name":"bar0_19","type":"RECT","coords":[311,160,321,80]},{"name":"bar1_19","type":"RECT","coords":[311,80,321,4]},{"name":"bar0_20","type":"RECT","coords":[326,160,336,80]},{"name":"bar1_20","type":"RECT","coords":[326,80,336,4]},{"name":"bar2_21","type":"RECT","coords":[341,160,351,4]},{"name":"bar0_22","type":"RECT","coords":[356,160,366,45]},{"name":"bar1_22","type":"RECT","coords":[356,45,366,4]},{"name":"bar0_23","type":"RECT","coords":[371,160,381,77]},{"name":"bar1_23","type":"RECT","coords":[371,77,381,4]},{"name":"bar2_24","type":"RECT","coords":[386,160,396,4]},{"name":"bar2_25","type":"RECT","coords":[401,160,411,4]},{"name":"bar2_26","type":"RECT","coords":[416,160,426,4]},{"name":"bar2_27","type":"RECT","coords":[431,160,441,4]},{"name":"bar2_28","type":"RECT","coords":[446,160,456,4]},{"name":"bar2_29","type":"RECT","coords":[461,160,471,4]},{"name":"bar2_30","type":"RECT","coords":[476,160,486,4]},{"name":"bar2_31","type":"RECT","coords":[491,160,501,4]}]};
	var prjs_len = prjs_ts.length;
	var chartshape = $.grep(data.chartshape, function(item,i){
		var name = item.name;
		var barIdx = name.lastIndexOf('_');
		return name.indexOf('bar') === 0 && name.substring(barIdx+1,name.length)<prjs_len;
	});
	var map = "<map name='"+mapname+"'>";
	$.each(chartshape, function(i, item){
		map += "<area name='"+item.name+"' shape='RECT' coords='"+item.coords+"' href='#'  title=''>";
	});
	map += "</map>";
	$('#'+chartholder).prepend(map);
	//window.alert($('#'+chartholder).html());
}

function create_chart(projects,chartholder,mapname){
	var len = projects.length;
	var passdata = faildata = blockdata = '';
	function get_case_number(){
		if($('.test_summary').length > 0){
			var summary = $($('.test_summary').get(0)).text();
			var number = summary.match(/total - (\d+)/m);
			if(number) number = number[1];
			return number;
		}
		return 100;
	}
	$.each(projects, function(i,prj){
		var lbl = prj.label;
		var pass = prj.pass;
		var fail = prj.fail;
		if(prj.block){
			passdata += '-1'; faildata += '-1'; blockdata += '100';
		}
		else{
			passdata += pass; faildata += fail; blockdata += '-1';
		}
		if(i < (len-1)){
			passdata += ','; faildata += ','; blockdata += ',';
		}
	});
	var case_number = get_case_number();
	//window.alert(case_number);
	var chart_api = google_chart + 
		"cht=bvs&chbh=10,5,10&chm=D,00aa33,0,0.5:0.5,2&chs=600x200&chxt=x,y,r,x&chxl=3:|Load&chxp=3,50&chxr=0,1,"+
		len+"|1,0.0,1.0|2,0,"+case_number+"&chd=t:" + passdata + "|" + faildata + "|" + blockdata +
		"&chco=50aa50,aa5050,aaaa50&chdl=PASS|FAIL|BLOCK";
	$('#'+chartholder).append('<div><img src="'+chart_api+'" useMap="#'+mapname+'" style="border-style:none;"/></div>');
}

function hover(){
	$("area[name*='bar']").hover(
		function(evt){
			var left = evt.clientX||evt.scrollLeft;
			var top = evt.clientY||evt.scrollTop;
			$('#hover_content').css('left',left+10).css('top',top+10);
			var barname =  $(this).attr('name');
			var bar_idx = barname.substring(barname.lastIndexOf('_')+1, barname.length);
			var prj_label = prjs_ts[bar_idx].label;
			var prj_pr = prjs_ts[bar_idx].pass;
			var prj_fr = prjs_ts[bar_idx].fail;
			var prj_block = prjs_ts[bar_idx].block;
			var prj_mtime = prjs_ts[bar_idx].modtime;
			var chtt = prj_label + "|" + prj_mtime;
			//$('#hover_content').append('<span>'+prj_label+'</span><br/>');
			//$('#hover_content').append('<span>'+prj_mtime+'</span><br/>');
			if(!prj_block){
				var chd = prj_pr + "," + prj_fr;
				var chl = prj_pr + "|" + prj_fr;
				var p3_chart = google_chart + "cht=p3&chs=240x120&chtt=" + chtt +
					"&chco=50aa50,aa5050&chf=c,lg,90,FFE7C6,0,76A4FB,0.75|bg,s,76A4FB&chl="+chl+"&chd=t:"+chd;
				p3_chart = encodeURI(p3_chart);
				$('#hover_content').append('<img src="'+p3_chart+'"/>');
			}
			else{
				var p3_chart = google_chart + "cht=p3&chs=240x120&chtt=" + chtt +
					"&chco=aaaa50&chf=c,lg,90,FFE7C6,0,76A4FB,0.75|bg,s,76A4FB&chl=BLOCK&chd=t:100";
				p3_chart = encodeURI(p3_chart);
				$('#hover_content').append('<img src="'+p3_chart+'"/>');
			}
			$('#hover_content').show();
		},
		function(evt){
			$('#hover_content').empty().hide();
		}
	);
}

function addchart4summay(){
	if($('.test_summary').length == 1){
		$('#hover_content').after($('.test_summary').clone());
	}
	$('.test_summary').each(function(){
		var pr = $(this).text().match(/pass rate in the log - (\d{1,3}\.\d{1,2})/m);
		if(pr) pr = pr[1];
		var fr = (100-pr).toFixed(2);
		var chd = pr + "," + fr;
		var chl = pr + "|" + fr;
		var p3_chart = google_chart + "chs=300x100&amp;cht=p3&amp;chd=t:" + chd + "&amp;chl=" + chl + "&amp;chco=50aa50,aa5050&chdl=PASS|FAIL";
		$(this).append('<img src="' + p3_chart + '"/>');
	});
}

function toggle(selctor){
	$(selctor).toggle(
		function(evt){ $(this).next().show("slow"); },
		function(evt){ $(this).next().hide("slow"); }
	);
}

function toggleElement(elem){
	function nextElement(elem){
		var nextElem = elem.nextSibling;
		while(nextElem.nodeType != elem.nodeType){
			nextElem = nextElem.nextSibling;
		}
		return nextElem;
	}
	var nextElem = nextElement(elem);
	if ( elem.addEventListener ) {
		elem.addEventListener('click',function(evt){
			if(nextElem.style.display == "none"){
				nextElem.style.display = "block";
			}
			else{
				nextElem.style.display = "none";
			}
		}, true);
	}
	else if ( elem.attachEvent ) {
		elem.attachEvent('onclick',function(evt){
			if(nextElem.style.display == "none"){
				nextElem.style.display = "block";
			}
			else{
				nextElem.style.display = "none";
			}
		}, true);
	}
}

function getElementsByClassName(classname){
	//Firefox
	if(document.documentElement.getElementsByClassName){
		return document.documentElement.getElementsByClassName(classname);
	}
	//IE
	else{
		var elems = document.getElementsByTagName('div');
		var result = [];
		for(var i=0;i<elems.length;i++){
			if(elems[i].className == classname){
				result.push(elems[i]);
			}
		}
		return result;
	}
}

function toggleElements(classname){
	var elems = getElementsByClassName(classname);
	for(var i=0;i<elems.length;i++){
		toggleElement(elems[i]);
	}
}

try{
	google.load("jquery", "1.3.1");
	google.setOnLoadCallback(function() {
		addchart4summay();
		toggle('.test_particular');
		if($('.part').length > 0) toggle('.part');
		if(prjs_ts){
			if(prjs_ts.length > 32){ //only support 32 projects for the picture size & json data
				prjs_ts = prjs_ts.slice(prjs_ts.length-32);
			}
			create_chartmap('ncsreport','ncsreportmap');
			create_chart(prjs_ts,'ncsreport','ncsreportmap');
			//window.alert($('#ncsreport').html());
			hover();
		}
		$('#ncsreport').prepend('<span>Below is the quick check for history CoSim NCS status report:<span>');
		//toggle('#ncsreport span');
		$('#ncssrlist').prepend('<span>Below is the quick check for CoSim SR list</span>');
		//toggle('#ncssrlist span');
	});
}
catch(e){
	window.alert("Cannot connect to google service, please check your network access service!");
	toggleElements('test_particular');
	toggleElements('part');
	//throw e;
}