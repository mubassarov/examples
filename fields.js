function CheckFields(obj, mode) {
    if (obj.id == 'search') {
	GoSearch(obj.value);
	return true;
    } else if (obj.nodeName == 'SPAN' || obj.nodeName == 'DIV' || 
		(obj.nodeName == 'INPUT' && (obj.name == 'term' || obj.name == 'account' || obj.name == 'enable')) || 
		(obj.nodeName == 'SELECT' && (obj.name.substring(0, 7) == 'skipacl')))
	parentObj = obj
    else {
	parentObj = FindParentElement(obj, 'SPAN');
	if (!parentObj) {
	    parentObj = FindParentElement(obj, 'DIV');
	    if (!parentObj) {
		return true;
	    }
	}
    }
    obj = $(parentObj);
    var mode = mode?mode:obj.attr('mode');
    var ID = obj.attr('id');
    if (mode == 'vlan') {
	var typeID = $('#' + ID + 'type').length?$('#' + ID + 'type').val():0;
	if (typeID == 6) {
	    $('#' + ID + 'vlan').val(0);
	    $('#' + ID + 'gw').val('');
	}
	if ($('#' + ID + 'vlan').length &&
	    $('#' + ID + 'vlan').attr('type') != 'hidden' && 
	    ($('#' + ID + 'vlan').val() == '' || 
		isNaN(parseInt($('#' + ID + 'vlan').val()))))
	    $('#' + ID + 'vlan')[0].focus()
	else if (!CheckNet($('#' + ID + 'nw').val(), 1))
	    $('#' + ID + 'nw')[0].focus()
	else if ($('#' + ID + 'gw').length &&
		$('#' + ID + 'gw').attr('type') != 'hidden' &&
		$('#' + ID + 'gw').val() != '' && 
		!CheckNet($('#' + ID + 'gw').val(), 0))
	    $('#' + ID + 'gw')[0].focus()
	else {
	    if ($(obj).attr('group') && $(obj)[0].firstElementChild.nodeName == "TABLE") {
		var inx = $('#g' + $('#gn' + $('#group').accordion("option", "active")).attr('group')).tabs("option", "active");
		if (isInt(inx))
		    $('#g'+obj.attr('group'))[0].firstElementChild.children[inx].firstElementChild.firstElementChild.textContent = 
			($('#' + ID + 'vlan').val()?$('#' + ID + 'vlan').val():obj.attr('vlan')) + 
			($('#' + ID + 'alias').val()?('/'+$('#' + ID + 'alias').val()):'');
	    }
	    CloseVLANdialog();
	    SendAjaxRequest('index.cgi', 
			    "mode=vlan&act="+(obj.attr('idvlan')?'edit':'create')+
				"&ajax=1&id="+obj.attr('idvlan')+
				"&group="+($('#' + ID + 'group').length?$('#' + ID + 'group').val():obj.attr('group')?obj.attr('group'):'')+
				"&vlan="+($('#' + ID + 'vlan').val()?$('#' + ID + 'vlan').val():'')+
				"&nw="+$('#' + ID + 'nw').val()+
				"&gw="+($('#' + ID + 'gw').val()?$('#' + ID + 'gw').val():'')+
				"&alias="+$('#' + ID + 'alias').val()+
				"&desc="+$('#' + ID + 'desc').val()+
				($('#' + ID + 'mng').is(':checked')?
				    '&mng=1':'')+
				($('#' + ID + 'disc').is(':checked')?
				    '&disc=1':'')+
				(typeID?
				    ('&typeid='+typeID):''),
			    1);
	}
    } else if (mode == 'object') {
	if ($('#' + ID + 'name').length &&
		$('#' + ID + 'name').val() == '')
	    $('#' + ID + 'name')[0].focus()
	else if ($('#' + ID + 'addr').length &&
		($('#' + ID + 'addr')[0].tagName == 'INPUT') &&
		!CheckNet($('#' + ID + 'addr').val(), 0) &&
		!CheckNet($('#' + ID + 'addr').val(), 1))
	    $('#' + ID + 'addr')[0].focus()
	else {
	    editingObj = obj;
	    WaitColorizeElement('#' + ID + 'line');
	    SendAjaxRequest('index.cgi',
			    "mode=object&act="+(obj.attr('idobject')?'edit':'create')+
				'&ajax=1&item=' + ID + 'line' +
				'&id'+(obj.attr('realobject') == 1?'object':'')+"="+obj.attr('idobject')+
				'&vlan='+obj.attr('vlan')+
				($('#' + ID + 'name').length?
				    '&name='+$('#' + ID + 'name').val():'')+
				(($('#' + ID + 'addr').length && ($('#' + ID + 'addr')[0].tagName == 'INPUT'))?
				    '&address='+$('#' + ID + 'addr').val():'')+
				($('#' + ID + 'type').length?
				    '&type='+$('#' + ID + 'type').val():'')+
				($('#' + ID + 'role').length?
				    '&role='+$('#' + ID + 'role').val():'')+
				($('#' + ID + 'vendor').length?
				    '&vendor='+$('#' + ID + 'vendor').val():'')+
				($('#' + ID + 'model').length?
				    '&model='+$('#' + ID + 'model').val():'')+
				($('#' + ID + 'loop').length?
				    '&loopback'+$('#' + ID + 'loop').val():'')+
				($('#' + ID + 'login').length?
				    '&login='+$('#' + ID + 'login').val():'')+
				($('#' + ID + 'pass').length?
				    '&pass='+$('#' + ID + 'pass').val():'')+
				($('#' + ID + 'enable').length?
				    '&enable='+$('#' + ID + 'enable').val():'')+
				($('#' + ID + 'comm').length?
				    '&community='+$('#' + ID + 'comm').val():'')+
				($('#' + ID + 'acl').length?
				    '&acl='+$('#' + ID + 'acl').val():'')+
				($('#' + ID + 'mac').length?
				    '&mac='+$('#' + ID + 'mac').val():'')+
				($('#' + ID + 'sn').length?
				    '&sn='+$('#' + ID + 'sn').val():'')+
				($('#' + ID + 'geo').length?
				    '&geo='+$('#' + ID + 'geo').val():'')+
				($('#' + ID + 'geoid').length?
				    '&geoid='+$('#' + ID + 'geoid').val():'')+
				($('#' + ID + 'city').length?
				    '&city='+$('#' + ID + 'city').val():'')+
				($('#' + ID + 'desc').length?
				    ('&desc='+$('#' + ID + 'desc').val()):'')+
				($('#' + ID + 'description').length?
				    ('&description='+$('#' + ID + 'description').val()):''),
			    0);
	}
    } else if (mode == 'newobject') {
	if (!CheckNet($('#' + ID + 'addr').val(), 0) &&
		!CheckNet($('#' + ID + 'addr').val(), 1))
	    $('#' + ID + 'addr')[0].focus();
	else if ($('#' + ID + 'obj').val() == 'new' &&
		    $('#' + ID + 'name').val() == '')
	    $('#' + ID + 'name')[0].focus()
	else {
	    editingObj = obj;
	    CloseCreateObjectDialog();
	    SendAjaxRequest('index.cgi',
			    "mode=object&act=" + (obj.attr('idobj') == ''?'create':'edit') +
				"&ajax=1&idobject=" + $('#' + ID + 'obj').val()+
				'&vlan=' + obj.attr('vlan') +
				'&id=' + obj.attr('idobj') +
			        '&address=' + $('#' + ID + 'addr').val() +
				'&desc=' + $('#' + ID + 'desc').val() +
				($('#' + ID + 'obj').val() == 'new'?
				    ('&name='+$('#' + ID + 'name').val() +
				    '&type='+$('#' + ID + 'type').val() +
				    '&role='+$('#' + ID + 'role').val() +
				    '&vendor='+$('#' + ID + 'vendor').val() +
				    '&model='+$('#' + ID + 'model').val() +
				    '&loopback='+$('#' + ID + 'loop').val() +
				    '&login='+$('#' + ID + 'login').val() +
				    '&pass='+$('#' + ID + 'pass').val() +
				    '&community='+$('#' + ID + 'comm').val() +
				    '&description='+$('#' + ID + 'description').val()):''),
			    1);
	}
    } else if (mode == 'newobjects') {
	if (!$('#' + ID + 'quantity').val().length || $('#' + ID + 'quantity').val() < 1) {
	    $('#' + ID + 'quantity')[0].focus();
	} else {
	    editingObj = obj;
	    CloseCreateObjectDialog();
	    SendAjaxRequest('index.cgi',
			    'mode=object&act=delivery&ajax=1' +
				'&storage=' + obj.attr('vlan') +
				'&group=' + $('#' + ID + 'group').val() +
				'&quantity=' + $('#' + ID + 'quantity').val() +
				'&name=' + $('#' + ID + 'name').val()+
				'&desc=' + $('#' + ID + 'description').val()+
				'&type='+$('#' + ID + 'type').val()+
				'&role='+$('#' + ID + 'role').val()+
				'&vendor='+$('#' + ID + 'vendor').val()+
				'&model='+$('#' + ID + 'model').val(),
			    1);
	}
    } else if (mode == 'group') {
	if ($('#' + ID + 'name').val() == '')
	    $('#' + ID + 'name')[0].focus()
	else
	    SendAjaxRequest('index.cgi', 
			    "mode=group&act="+(obj.attr('group')?'edit':'create')+
				"&ajax=1"+
				"&group="+obj.attr('group')+
				"&name="+$('#' + ID + 'name').val() +
				($('#' + ID + 'table').length?
				    ("&tabled="+$('#' + ID + 'table').val()):''),
			    1);
    } else if (mode == 'link') {
	var speed = $('#'+ID+'speed').val();
	if ($('#'+ID+'suffix').val() == 'm')
	    speed *= 1000
	else if ($('#'+ID+'suffix').val() == 'g')
	    speed *= 1000000;
	WaitLinkCell($(obj).attr('idlink'), '');
	SendAjaxRequest('index.cgi',
			"mode=link&act=speed&ajax=1"+
			    "&link=" + obj.attr('idlink') + 
			    "&value=" + speed,
			0);
    } else if (mode == 'trunk') {
	var id = $(obj).attr('idtrunk');
	WaitLinkCell(id, 'HEAD');
	SendAjaxRequest('index.cgi',
			"mode=link&act=trunk&ajax=1"+
			    "&trunk=" + id + 
			    "&name=" + $('#trunk' + id + 'name').val() + 
			    "&type=" + $('#trunk' + id + 'type').val(),
			0);
    } else if (mode == 'user') {
	if (!$('#'+ID+'fio').val().length) 
	    $('#'+ID+'fio')[0].focus()
	else if (!$('#'+ID+'login').val().length)
	    $('#'+ID+'login')[0].focus()
	else if (!obj.attr('iduser') && !$('#'+ID+'pass').val().length)
	    $('#'+ID+'pass')[0].focus()
	else {
	    SendAjaxRequest('index.cgi',
			    "mode=user&act="+(obj.attr('iduser')?'edit':'create')+
				"&ajax=1"+
				"&id="+obj.attr('iduser')+
				"&login="+$('#'+ID+'login').val()+
				"&fio="+$('#'+ID+'fio').val()+
				"&password="+escape($('#'+ID+'pass').val())+
			        "&email="+$('#'+ID+'email').val(),
			    1);
	}
    } else if (mode == 'lang') {
	if (!$('#'+ID+'name').val().length)
	    $('#'+ID+'name').focus()
	else if (!$('#'+ID+'title').val().length)
	    $('#'+ID+'title').focus()
	else {
	    SendAjaxRequest('index.cgi',
			    'mode=lang&act=create'+
				'&ajax=1'+
				'&name='+$('#'+ID+'name').val()+
				'&title='+$('#'+ID+'title').val(),
			    1);
	}
    } else if (mode == 'term') {
	if (!$('#'+ID).val().length)
	    $('#'+ID).focus()
	else {
	    WaitColorizeElement('#'+ID);
	    SendAjaxRequest('index.cgi',
			    'mode=term&act=edit'+
				'&ajax=1'+
				'&id='+$('#'+ID).attr('termid')+
				'&value='+$('#'+ID).val(),
			    0);
	}
    } else if (mode == 'newterm') {
	if (!$('#'+ID).val().length)
	    $('#'+ID).focus()
	else {
	    WaitColorizeElement('#'+ID);
	    SendAjaxRequest('index.cgi',
			    'mode=term&act=create'+
				'&ajax=1'+
				'&value='+$('#'+ID).val(),
			    1);
	}
    } else if (mode == 'account') {
	id=$('#'+ID).attr('idaccount');
	if (!$('#a'+id+'login').val().length)
	    $('#a'+id+'login').focus()
	else if (!$('#a'+id+'password').val().length)
	    $('#a'+id+'password').focus()
	else {
	    WaitColorizeElement('#account'+id+'line');
	    SendAjaxRequest('index.cgi',
			    'mode=account&act='+(id == '0'?'create':'edit')+
				'&ajax=1'+
				'&id='+id+
				'&login='+$('#a'+id+'login').val()+
				'&password='+escape($('#a'+id+'password').val()),
			    id == '0'?1:0);
	}
    } else if (mode == 'enable') {
	id=$('#'+ID).attr('idenable');
	if (!$('#e'+id+'enable').val().length)
	    $('#e'+id+'enable').focus()
	else {
	    WaitColorizeElement('#e'+id+'line');
	    SendAjaxRequest('index.cgi',
			    'mode=enable&act='+(id == '0'?'create':'edit')+
				'&ajax=1'+
				'&id='+id+
				'&enable='+$('#e'+id+'enable').val(),
			    id == '0'?1:0);
	}
    } else if (mode == 'eqgroup') {
	SendAjaxRequest('index.cgi',
			    'mode=group&act=edit'+
				'&ajax=1'+
				'&id='+obj.attr('group')+
				'&enable='+$('#' + ID + 'en').val()+
				'&acl='+$('#' + ID + 'acl').val(),
			    1);
    } else if (mode == 'acl') {
	if (!$('#' + ID + 'ip').val().length) {
	    $('#' + ID + 'ip').focus()
	} else {
	    SendAjaxRequest('index.cgi',
			    'mode=acl&act=edit'+
				'&ajax=1'+
				'&id='+obj.attr('acl')+
				'&group='+obj.attr('idgroup')+
				'&vlan='+$('#' + ID + 'vlan').val()+
				'&eqtype='+$('#' + ID + 'eqtype').val()+
				'&role='+$('#' + ID + 'role').val()+
				'&vendor='+$('#' + ID + 'vendor').val()+
				'&model='+$('#' + ID + 'model').val()+
				'&type='+$('#' + ID + 'type').val()+
				'&ip='+$('#' + ID + 'ip').val()+
				'&title='+$('#' + ID + 'title').val(),
			    1);
	}
    } else if (mode == 'skipacl') {
	if (ID == 'skipacltype' || ID == 'skipaclvalue') {
	    SaveSkipGroupACL($('#skipacltype').val(), $('#skipaclvalue').val(), 0)
	}
    } else if (mode == 'storage') {
	SendAjaxRequest('index.cgi',
			"mode=storage&act=edit&ajax=1" +
			    "&storage=" + $(obj).attr('storage') + 
			    ($('#' + ID + 'date').length?"&date=" + $('#' + ID + 'date').val():'') + 
			    "&name=" + $('#' + ID + 'name').val() + 
			    "&desc=" + $('#' + ID + 'desc').val(),
			1);
    } else if (mode == 'placed') {
	WaitColorizeElement('#' + ID + 'line');
	SendAjaxRequest('index.cgi',
			'mode=object&act=placed'+
			    '&ajax=1&item=' + ID + 'line' +
			    '&object='+$('#' + ID).attr('idobject'),
			0);
    } else if (mode == 'geolocation') {
        var geoloc = $('#' + ID).attr('idgeoloc');
        if (!geoloc)
            geoloc = 0;
        if (!$('#' + ID + 'name').val().length) {
            $('#' + ID + 'name').focus()
        } else if (!$('#' + ID + 'lat').val().length) {
            $('#' + ID + 'lat').focus()
        } else if (!$('#' + ID + 'lng').val().length) {
            $('#' + ID + 'lng').focus()
        } else {
	    SendAjaxRequest('index.cgi',
			'mode=location&act=' + (geoloc == '0'?'create':'edit') +
			    '&ajax=1&id=' + (geoloc == '0'?$('#' + ID).attr('idgroup'):geoloc) +
			    '&name=' + $('#' + ID + 'name').val() +
			    '&lat=' + $('#' + ID + 'lat').val() +
			    '&lng=' + $('#' + ID + 'lng').val(),
			0);
	}
    }
}

function SimpleNextField(obj, id) {
    var flag = false;
    var focused = null;
    var edited = null;
    var mask = 'input[type=text], input[type=checkbox], input[type=password], select';
    while (focused == null) {
	$(obj).find(mask).each(function () {
	    if (flag) {
		if (!this.readOnly && this.style.display != "none") {
		    focused = this;
		    flag = false;
		}
	    } else if (focused == null && this.id == id) {
		edited = this;
		flag = true;
	    }
	});
	flag = true;
    }
//    if (focused == null)
//        focused = $(obj).find(mask)[0];
    focused.focus();
    return [flag, edited, focused];
}

function NextField(obj) {
    if (obj.nodeName != 'INPUT')
	return true;
    var id = obj.id;
    if (id == 'search') {
	GoSearch(obj.value);
	return true;
    }

    var name = obj.name;
    var parentObj = FindParentElement(obj, 'SPAN');
    if (!parentObj) {
	    parentObj = FindParentElement(obj, 'DIV');
	    if (!parentObj)
		return true;
    }
    obj = $(parentObj);
    var mode = obj.attr('mode');
    var ID = obj.attr('id');
    if (mode == 'vlan') {
	    if (name == 'vlan') {
		var group = $('#gn' + $('#group').accordion("option", "active"));
		if (group.length && $('#' + ID + 'nw').val() == '') {
		    var name = group[0].firstElementChild.children[1].firstElementChild.value;
		    if (name.match(ip)) {
			var tmp = new Array();
			tmp = name.split(".");
			$('#' + ID + 'nw').val(tmp[0]+'.'+tmp[1]+'.'+tmp[2]+'.'+$('#' + ID + 'vlan').val()+'/30');
		    }
		}
		$('#' + ID + 'nw')[0].focus()
	    } else if (name == 'nw') {
		var typeID = $('#' + ID + 'type').length?$('#' + ID + 'type').val():0;
		if (typeID == 6) {
		    $('#' + ID + 'alias')[0].focus();
		} else {
		    if ($('#' + ID + 'gw').type == 'hidden')
			$('#' + ID + 'alias')[0].focus()
		    else if ((name == 'nw' && $('#' + ID + 'gw').val() == '') && 
			    $('#' + ID + 'nw').val() != '') {
			var tmp = new Array();
			tmp = $('#' + ID + 'nw').val().split("/");
			var net = tmp[1];
			var count = 1;
			if (net >= 24 && net <= 30) {
			    for (i = 0; i <= 31 - net; i++)
				count = count * 2;
			    tmp = tmp[0].split(".");
			    tmp[3] = tmp[3] - tmp[3] % count + (name == 'nw'?1:(count - 1));
			    $('#' + ID + (name == 'nw'?'gw':'bc')).val(tmp[0] + '.' + tmp[1] + '.' + tmp[2] + '.' + tmp[3]);
			}
		    }
		    $('#' + ID + (name == 'nw'?'gw':'alias'))[0].focus()
		}
	    } else if (name == 'gw')
		$('#' + ID + 'alias')[0].focus()
	    else if (name == 'alias')
		$('#' + ID + 'desc')[0].focus()
	    else if (name == 'description') {
		var typeID = $('#' + ID + 'type').length?$('#' + ID + 'type').val():0;
		if (typeID == 6)
		    $('#' + ID + 'nw')[0].focus()
		else
		    $('#' + ID + 'vlan')[0].focus();
	    }
    } else if (mode == 'object' || mode == 'newobject')
        SimpleNextField(obj[0].firstElementChild, id)
    else if (mode == 'chartinfo') {
	    var flag = false;
	    var focused = null;
	    var edited = null;
	    obj.children('div').each(function () {
		if ($(this).css('visibility') == 'visible')
	    	    $(this).children('input[type=text], input[type=checkbox], select').each(function() {
			if (flag) {
			    focused = this;
			    flag = false;
			}
			else if (this.name == name) {
			    edited = this;
			    flag = true;
			}
		    });
	    });
	    if (focused == null)
		focused = $(obj.children('div')[0]).children('input[type=text], input[type=checkbox], select')[0];
	    focused.focus();
	    if (currentChart != null && typeof(currentChart) == 'object') {
		var tmp;
		if ($(currentChart).hasClass('link')) {
		    if (edited.name == 'speed' || edited.name == 'speedsuffix' || 
			    edited.name == 'trunk' || edited.name == 'count')
			tmp = $(currentChart).attr('speed') + ' ' + 
			        $(currentChart).attr('speedsuffix') + ' ' +
				$(currentChart).attr('trunk');
		    if ((edited.name == 'speed' || edited.name == 'speedsuffix') &&
			$(currentChart).attr('trunk') == '1')
			RefreshTrunkSpeed(0);
		    $(currentChart).attr(edited.name, edited.type == 'checkbox'?
					edited.checked?1:0:
					edited.name == 'speed' && !edited.value?0:edited.value);
		    if ((edited.name == 'speed' || edited.name == 'speedsuffix') &&                                 
			$(currentChart).attr('trunk') != '1') {
			var temp = $(currentChart).attr('speed');
			if ($(currentChart).attr('speedsuffix') == 'm')
			    temp *= 1000
			else if ($(currentChart).attr('speedsuffix') == 'g')
			    temp *= 1000000;
			$(currentChart).attr('speed0', temp);
		    }
		    if (edited.name == 'count' && !$('#InformationTrunk').is(':checked')) {
			$('#InformationTrunk').attr('checked', true);
		        $(currentChart).attr('trunk', '1');
		    }
		    if (edited.name == 'speed' || edited.name == 'speedsuffix' || 
			    edited.name == 'trunk' || edited.name == 'count')
			CheckLinkSpeed(currentChart, tmp);
		    RefreshLinkAnnotation($(currentChart));
		    if ((edited.name == 'trunk' && edited.checked) || edited.name == 'count')
			ConfigTrunk();
		} else if ($(currentChart).hasClass('flowicon')) {
		    $(currentChart).attr(edited.name, edited.value);
		    RefreshEqAnnotation($(currentChart));
		}
	    }
    } else if (mode == 'link' || mode == 'trunk') {
        CheckFields(obj);
    } else if (mode == 'user') {
        SimpleNextField(obj, id)
    } else if (mode == 'eqgroup') {
        SimpleNextField(obj, id)
    } else if (mode == 'acl') {
	SimpleNextField(obj, id)
    }
}
