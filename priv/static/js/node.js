function Message(type, data, id){
    this.type = type;
    this.data = data;
    this.id = id;
}

function Node(id, parent, user_id, websocket){
    this.id = id;
    this.ws = websocket;
    this.user_id = user_id;
    this.events = [];
    this.dom(parent);
    this.websocket();
    this.stream();
}

Node.prototype.dom = function(parent){
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

Node.prototype.websocket = function(){
    var self = this;
    this.send("node", "");
    this.ws.onmessage = function(evt) {
        var evnt = JSON.parse(evt.data);
        if(evnt.id != self.id) return;
        self.events.push(evnt);
        if(self.events.length > 10) self.events.shift();
        self.display_event(evnt);
    };
}

Node.prototype.send = function(type, data){
    var m = new Message(type, data, this.id);
    this.ws.send(JSON.stringify(m));
}

Node.prototype.on = function(){
    this.send("light", "on");
}

Node.prototype.off = function(){
    this.send("light", "off");
}

Node.prototype.display_event = function(evnt){
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

Node.prototype.stream = function(){
    $("#stream"+this.id).attr("src", "/stream?node_id="+this.id+"&user_id="+this.user_id);
}
