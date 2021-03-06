<super-form>
    <form onsubmit={ submit } >
        <yield>
    </form>

    var self = this;
    var EL = self.root;
    var config = self.opts.opts || self.opts;
    var keyWords = ['insertTip', 'ajaxSubmit', 'submit'];   //保留字，不被覆盖

    self.presentWarning = '必填';
    self.emailWarning = '邮箱格式错误';
    self.mobileWarning = '手机格式错误';
    self.urlWarning = '网址格式错误';
    self.successTips = '通过';
    self.regWarning = '字段不符合验证规则';

    EL.loadData = function(newData, colName){
        colName = colName || 'data';
        self[colName] = newData;
        self.update();
    }

    for (i in config) {
        if (keyWords.indexOf(i) < 0) {
            self[i] = config[i];
        }
    }
    self.data = config.data;
    self.submitingText = config.submitingText || '提交中...';
    if (config.valid === undefined) {
        config.valid = true;
    }
    
    self.maxWarning = config.maxWarning || function(n) {
        return '不得超过' + n + '个字符';
    }
    self.minWarning = config.minWarning || function(n) {
        return '不得小于' + n + '个字符';
    }

    self.removeTips = function() {
        var root = self.root;
        var tips = root.getElementsByClassName('tip-container');
        if (tips && tips.length) {
            del();
        }

        function del() {
            for (i = 0; i < tips.length; i++) {
                tips[i].parentNode.removeChild(tips[i]);
                if (tips.length) {
                    del();
                }
            }
        }
    }
    
    self.insertTip = function(dom, message, className){
        var tip = dom.nextElementSibling;
        if (tip && tip.className.match(/tip-container/)) {
            dom.parentNode.removeChild(tip);
        }
        var tipContainer = document.createElement('span');
        tipContainer.className = className;
        tipContainer.innerHTML = message;
        utils.insertAfter(tipContainer, dom);
    }

    self.onValidRefuse = config.onValidRefuse || function(dom, errorTips) {
        self.insertTip(dom, errorTips, 'tip-container');
    }

    self.onValidPass = config.onValidPass || function(dom, successTips) {
        self.insertTip(dom, successTips, 'tip-container success');
    }

    self.ajaxSubmit = function(elems, url) {
        var params = '';
        for (var i = 0; i < elems.length; i++) {
            if (elems[i].name) {
                if (elems[i].tagName === "SELECT") {
                    value = elems[i].options[elems[i].selectedIndex].value;
                    params += elems[i].name + "=" + encodeURIComponent(value) + "&";
                } 
                else if (elems[i].type === "checkbox" || elems[i].type === "radio"){
                    if (elems[i].checked) {
                        value = elems[i].value;
                        params += elems[i].name + "=" + encodeURIComponent(value) + "&";
                    }
                }
                else {
                    value = elems[i].value;
                    params += elems[i].name + "=" + encodeURIComponent(value) + "&";
                }
            }
            if (elems[i].type === "submit") {
                var submitbtn = elems[i];
                var submitText = submitbtn.value || submitbtn.innerText;
                submitbtn.disabled = 'disabled';
                submitbtn.value = self.submitingText;
            }
        }
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("POST", url, true);
        xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        xmlhttp.send(params);
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState === 4) { 
                if (xmlhttp.status === 200) {
                    try {
                        var result = JSON.parse(xmlhttp.responseText);
                        config.callback(result);
                    }catch(e){
                        console.log(e);
                    }
                }
                else {
                    config.errCallback(params);
                }
                self.removeTips();
                submitbtn.value = submitText;
                submitbtn.disabled = false;
            } 
        };
    }

    submit(e) {
        var validArr = [];
        var elems = self.root.getElementsByTagName('form')[0].elements;
        var url = self.root.getAttribute('action');

        if (config.valid) {
            for (var i = 0; i < elems.length; i++) {
                var valid = elems[i].getAttribute('valid');
                var max = elems[i].getAttribute('max');
                var min = elems[i].getAttribute('min');
                var v = elems[i].value; 
                var name = elems[i].name;
                var dom = elems[i];
                if (name && valid) {
                    if (valid === 'email') {
                        if (!v.match(/^([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+(.[a-zA-Z0-9_-])+/)) {
                            validArr.push(name);
                            self.onValidRefuse(dom, self.emailWarning);
                        }
                        else {
                            self.onValidPass(dom, self.successTips); 
                        }
                    }
                    else if (valid === 'mobile') {
                        if (!v.match(/^1[3|4|5|8][0-9]\d{4,8}$/)) {
                            validArr.push(name);
                            self.onValidRefuse(dom, self.mobileWarning);
                        }
                        else {
                            self.onValidPass(dom, self.successTips); 
                        }
                    }
                    else if (valid === 'url') {
                        if (!v.match(/((http|ftp|https|file):\/\/([\w\-]+\.)+[\w\-]+(\/[\w\u4e00-\u9fa5\-\.\/?\@\%\!\&=\+\~\:\#\;\,]*)?)/)) {
                            validArr.push(name);
                            self.onValidRefuse(dom, self.urlWarning);
                        }
                        else {
                            self.onValidPass(dom, self.successTips); 
                        }
                    }
                    else if (valid === 'present') {
                        v = v.replace(' ', '');
                        if (!v.length) {
                            validArr.push(name);
                            self.onValidRefuse(dom, self.presentWarning);
                        }
                        else {
                            self.onValidPass(dom, self.successTips);
                        }
                    }
                    else if (valid.match(/^\/\S+\/$/)) {
                        valid = valid.replace(/^\//, '');
                        valid = valid.replace(/\/$/, '');
                        var reg = new RegExp(valid);
                        if (reg.test(v)) {
                            self.onValidPass(dom, self.successTips); 
                        }
                        else {
                            validArr.push(name);
                            self.onValidRefuse(dom, self.regWarning);
                        }
                    }
                }
                else if (name && max) {
                    var max = parseInt(max, 10);
                    if (v.length > max) {
                        validArr.push(name);
                        self.onValidRefuse(dom, self.maxWarning(max));
                    }
                    else {
                        self.onValidPass(dom, self.successTips);
                    }
                }
                else if (name && min) {
                    var min = parseInt(min, 10);
                    if (v.length < min) {
                        validArr.push(name);
                        self.onValidRefuse(dom, self.minWarning(min));
                    }
                    else {
                        self.onValidPass(dom, self.successTips);
                    }
                }
            }
        }
        
        if (!validArr.length) {
            e.preventDefault();
            if (config.normalSubmit) { 
                self.root.firstChild.setAttribute('action', self.root.getAttribute('action'));
                return true;
            }
            else {
                self.ajaxSubmit(elems, url);
            }
        }
        else {
            return false;
        }
    }

</super-form>