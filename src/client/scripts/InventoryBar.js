var InventoryBar,
    modulo = function (a, b) {
        return ((+a % (b = +b)) + b) % b;
    };

InventoryBar = class InventoryBar {
    constructor(game) {
        var j, k, l;
        this.game = game;
        for (j = 0; j <= 9; ++j) {
            $(".player_hp").append("<span class='hp'></span> ");
        }
        for (k = 0; k <= 9; ++k) {
            $(".player_food").append("<span class='food'></span> ");
        }
        for (l = 1; l <= 9; ++l) {
            $(".inv_bar").append(
                "<span class='inv_box item' data-texture=''></span> "
            );
        }
        this.listen();
    }

    setHp(points) {
        var i, j, k, l, lista, ref;
        lista = {};
        for (i = j = 1; j <= 10; i = ++j) {
            lista[i - 1] = "empty";
            $(".hp")
                .eq(i - 1)
                .removeClass("empty");
            $(".hp")
                .eq(i - 1)
                .removeClass("full");
            $(".hp")
                .eq(i - 1)
                .removeClass("half");
        }
        if (points !== 0) {
            for (
                i = k = 1, ref = (points + (points % 2)) / 2;
                1 <= ref ? k <= ref : k >= ref;
                i = 1 <= ref ? ++k : --k
            ) {
                lista[i - 1] = "full";
            }
            if (points % 2 === 1) {
                lista[(points + (points % 2)) / 2 - 1] = "half";
            }
        }
        for (i = l = 1; l <= 10; i = ++l) {
            $(".hp")
                .eq(i - 1)
                .addClass(lista[i - 1]);
        }
    }

    setFood(points) {
        var i, j, k, l, lista, ref;
        lista = {};
        for (i = j = 1; j <= 10; i = ++j) {
            lista[10 - i] = "empty";
            $(".food")
                .eq(10 - i)
                .removeClass("empty");
            $(".food")
                .eq(10 - i)
                .removeClass("full");
            $(".food")
                .eq(10 - i)
                .removeClass("half");
        }
        if (points !== 0) {
            for (
                i = k = 1, ref = (points + (points % 2)) / 2;
                1 <= ref ? k <= ref : k >= ref;
                i = 1 <= ref ? ++k : --k
            ) {
                lista[10 - i] = "full";
            }
            if (points % 2 === 1) {
                lista[10 - (points + (points % 2)) / 2] = "half";
            }
        }
        for (i = l = 1; l <= 10; i = ++l) {
            $(".food")
                .eq(10 - i)
                .addClass(lista[10 - i]);
        }
    }

    setXp(level, progress) {
        if (level === 0) {
            $(".player_xp").hide();
        } else {
            $(".player_xp").show();
            $(".player_xp").text(level);
        }
        return $(".xp_bar").css("width", `${500 * progress}px`);
    }

    setFocus(num) {
        $(".inv_cursor").css("left", `calc(50vw - 253px + 55*${num}px)`);
        this.game.socket.emit("invc", num);
    }

    updateInv(inv) {
        var i, j;
        for (i = j = 36; j <= 44; i = ++j) {
            if (inv[i] !== null) {
                $(".inv_box")
                    .eq(i - 36)
                    .attr("data-texture", inv[i].name);
                $(".inv_box")
                    .eq(i - 36)
                    .attr("data-amount", String(inv[i].count));
            } else {
                $(".inv_box")
                    .eq(i - 36)
                    .attr("data-texture", "");
                $(".inv_box")
                    .eq(i - 36)
                    .attr("data-amount", "0");
            }
        }
    }

    listen() {
        var _this, focus;
        focus = 0;
        this.setFocus(focus);
        _this = this;
        $(window).on("wheel", function (e) {
            if (_this.game.FPC.gameState === "gameLock") {
                if (e.originalEvent.deltaY > 0) {
                    focus++;
                } else {
                    focus--;
                }
                focus = modulo(focus, 9);
                return _this.setFocus(focus);
            }
        });
    }

    tick() {
        var i, items, j, list, pos, ref, tex, url;
        list = $(".item");
        for (
            i = j = 0, ref = list.length - 1;
            0 <= ref ? j <= ref : j >= ref;
            i = 0 <= ref ? ++j : --j
        ) {
            if ($(list[i]).attr("data-texture") === "") {
                url = "";
            } else {
                url = "/assets/items/items-Atlas.png";
                tex = 43;
                items = this.game.al.get("itemsMapping");
                $(list[i]).css("background-repeat", "no-repeat");
                pos = items[$(list[i]).attr("data-texture")];
                $(list[i]).css(
                    "background-position",
                    `-${(pos.x - 1) * tex}px -${(pos.y - 1) * tex}px`
                );
                $(list[i]).css("background-size", `calc(1600px * ${tex / 50})`);
            }
            $(list[i]).css("background-image", `url(${url})`);
            $(list[i]).html(
                "<div style='z-index:99;text-align:right;position:relative;bottom:-22px;color:white;font-weight:bold;'>" +
                    $(list[i]).attr("data-amount") +
                    "</div>"
            );
            if (
                $(list[i]).attr("data-amount") === "0" ||
                $(list[i]).attr("data-amount") === "1"
            ) {
                $(list[i]).html(
                    "<div style='z-index:99;text-align:right;position:relative;bottom:-22px;color:white;font-weight:bold;'>&#8291</div>"
                );
            }
        }
    }
};

export { InventoryBar };