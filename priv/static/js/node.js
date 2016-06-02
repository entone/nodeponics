function WebSocketManager(ws){
    this.ws = ws;
    this.handlers = [];
    var self = this;
    this.ws.onmessage = function(evt){
        var evnt = JSON.parse(evt.data)
        for(var h in self.handlers){
            self.handlers[h][1].call(self.handlers[h][0], evnt);
        }
    }
}

WebSocketManager.prototype.add_handler = function(obj, handler){
    this.handlers.push([obj, handler])
}

WebSocketManager.prototype.send = function(message){
    this.ws.send(JSON.stringify(message));
}

function Message(type, data, id){
    this.type = type;
    this.data = data;
    this.id = id;
}

function Node(obj, parent, user_id, websocket){
    this.data = obj;
    this.id = this.data.id;
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
    this.send("node", "");
    this.ws.add_handler(this, this.onmessage);
}

Node.prototype.onmessage = function(evnt) {
    if(evnt.id != this.id) return;
    this.events.push(evnt);
    if(this.events.length > 10) this.events.shift();
    this.display_event(evnt);
};

Node.prototype.send = function(type, data){
    var m = new Message(type, data, this.id);
    this.ws.send(m);
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
