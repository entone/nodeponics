function node(id, parent, user_id){
    this.id = id;
    this.user_id = user_id;
    this.events = [];
    this.dom(parent);
    this.websocket();
    this.stream();
}

node.prototype.dom = function(parent){
    var elem = "<div class=\"col-sm-6 col-md-6\"> \
            <div class=\"thumbnail\"> \
                <img id=\"stream"+this.id+"\"> \
                <div class=\"caption\"> \
                    <div class=\"messages\" id=\"messages"+this.id+"\"></div> \
                    <div class=\"btn-group\" role=\"group\" > \
                        <button type=\"button\" class=\"btn btn-default\" id=\"on"+this.id+"\">ON</button> \
                        <button type=\"button\" class=\"btn btn-default\" id=\"off"+this.id+"\">OFF</button> \
                    </div> \
                </div> \
            </div> \
        </div>";
    var self = this;
    $(parent).append(elem);
    $("#on"+this.id).click(function(){
        self.on();
    });
    $("#off"+this.id).click(function(){
        self.off();
    });
}

node.prototype.websocket = function(){
    var self = this;
    this.ws = new WebSocket('ws:/'+window.location.host+'/ws?node_id='+this.id+'&user_id='+this.user_id);
    this.ws.onopen = function(evt) {
        console.log(evt);
    };
    this.ws.onclose = function(evt) {
        console.log(evt)
    };
    this.ws.onmessage = function(evt) {
        self.events.push(evt);
        if(self.events.length > 10) self.events.shift();
        self.display_event(evt);
    };
}

node.prototype.on = function(){
    var message = {type:"light", "data":"on"}
    this.ws.send(JSON.stringify(message));
}

node.prototype.off = function(){
    var message = {type:"light", "data":"off"}
    this.ws.send(JSON.stringify(message));
}

node.prototype.display_event = function(evt){
    console.log(evt.data);
    var evnt = JSON.parse(evt.data);
    if(evnt.type == "node_message" || evnt.type == "response") return;
    var messages = document.getElementById("messages"+this.id);
    var len = messages.childNodes.length;
    if(len > this.events.length) messages.removeChild(messages.firstChild);

    var v = evnt.value;
    try{
        v = JSON.stringify(v);
    }catch(e){
        v = v;
    }
    var e = document.createElement("div");
    e.innerHTML = evnt.type+": "+v;
    messages.appendChild(e);
    e.style.opacity = 0;
    window.getComputedStyle(e).opacity;
    e.style.opacity = 1;
}

node.prototype.stream = function(){
    $("#stream"+this.id).attr("src", "/stream?node_id="+this.id+"&user_id="+this.user_id);
}
