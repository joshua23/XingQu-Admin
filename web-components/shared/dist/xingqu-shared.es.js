var jr = Object.defineProperty;
var Er = (g, s, o) => s in g ? jr(g, s, { enumerable: !0, configurable: !0, writable: !0, value: o }) : g[s] = o;
var K = (g, s, o) => Er(g, typeof s != "symbol" ? s + "" : s, o);
import { createClient as _r } from "@supabase/supabase-js";
import Me, { useState as wr } from "react";
import { RefreshCw as Rr, Download as Cr, Maximize2 as Sr, MoreHorizontal as Tr, Minus as kr, TrendingDown as Or, TrendingUp as Pr } from "lucide-react";
import { ResponsiveContainer as Nr, AreaChart as Fr, CartesianGrid as ke, XAxis as Oe, YAxis as Pe, Tooltip as Ne, Area as Dr, LineChart as Ar, Line as Ir } from "recharts";
import { format as Fe } from "date-fns";
const te = { BASE_URL: "/", DEV: !1, MODE: "production", PROD: !0, SSR: !1 }, De = (g, s) => (te == null ? void 0 : te[g]) || s, Ae = {
  url: De("VITE_SUPABASE_URL", "https://your-project.supabase.co"),
  anonKey: De("VITE_SUPABASE_ANON_KEY", "your-anon-key")
}, Lr = _r(
  Ae.url,
  Ae.anonKey,
  {
    auth: {
      persistSession: !0,
      autoRefreshToken: !0
    },
    realtime: {
      params: {
        eventsPerSecond: 10
      }
    }
  }
), F = class F {
  constructor() {
    K(this, "client");
    K(this, "channels", /* @__PURE__ */ new Map());
    this.client = Lr;
  }
  // 获取单例实例
  static getInstance() {
    return F.instance || (F.instance = new F()), F.instance;
  }
  // 实时数据订阅
  subscribeToTable(s, o, i) {
    var h;
    const u = `${s}_${(i == null ? void 0 : i.column) || "all"}`;
    this.channels.has(u) && ((h = this.channels.get(u)) == null || h.unsubscribe());
    const y = this.client.channel(u).on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: s,
        ...i && { filter: `${i.column}=eq.${i.value}` }
      },
      o
    ).subscribe();
    return this.channels.set(u, y), y;
  }
  // 取消订阅
  unsubscribe(s) {
    var o;
    s && this.channels.has(s) ? ((o = this.channels.get(s)) == null || o.unsubscribe(), this.channels.delete(s)) : (this.channels.forEach((i) => i.unsubscribe()), this.channels.clear());
  }
  // 获取组件数据
  async getComponentData(s, o = {}) {
    try {
      const { data: i, error: u } = await this.client.rpc("get_component_data", {
        component_type: s,
        filters: o
      });
      if (u) throw u;
      return i;
    } catch (i) {
      throw console.error(`Error fetching ${s} data:`, i), i;
    }
  }
  // 更新组件配置
  async updateComponentConfig(s, o) {
    try {
      const { data: i, error: u } = await this.client.from("component_configs").update({
        config_data: o,
        updated_at: (/* @__PURE__ */ new Date()).toISOString()
      }).eq("id", s).select().single();
      if (u) throw u;
      return i;
    } catch (i) {
      throw console.error("Error updating component config:", i), i;
    }
  }
  // 记录组件使用日志
  async logComponentUsage(s, o, i = {}) {
    try {
      const { error: u } = await this.client.from("component_usage_logs").insert({
        component_id: s,
        feishu_user_id: this.getCurrentFeishuUserId(),
        action_type: o,
        action_data: i,
        ip_address: await this.getClientIP(),
        user_agent: navigator.userAgent
      });
      if (u) throw u;
    } catch (u) {
      console.error("Error logging component usage:", u);
    }
  }
  // 获取飞书用户ID
  getCurrentFeishuUserId() {
    return new URLSearchParams(window.location.search).get("feishu_user_id") || localStorage.getItem("feishu_user_id");
  }
  // 获取客户端IP (简化版)
  async getClientIP() {
    try {
      return (await (await fetch("https://api.ipify.org?format=json")).json()).ip;
    } catch {
      return null;
    }
  }
};
K(F, "instance");
let z = F;
class Mr extends z {
  // 获取实时指标
  async getRealTimeMetrics(s = []) {
    try {
      let o = this.client.from("realtime_metrics").select("*").gte("expires_at", (/* @__PURE__ */ new Date()).toISOString()).order("calculated_at", { ascending: !1 });
      s.length > 0 && (o = o.in("metric_name", s));
      const { data: i, error: u } = await o;
      if (u) throw u;
      const y = /* @__PURE__ */ new Map();
      return i == null || i.forEach((h) => {
        y.set(h.metric_name, {
          value: h.metric_value,
          calculatedAt: h.calculated_at,
          expiresAt: h.expires_at
        });
      }), Object.fromEntries(y);
    } catch (o) {
      throw console.error("Error fetching real-time metrics:", o), o;
    }
  }
  // 订阅实时指标更新
  subscribeToMetrics(s) {
    return this.subscribeToTable("realtime_metrics", async () => {
      const o = await this.getRealTimeMetrics();
      s(o);
    });
  }
}
const qr = new z(), Gr = new Mr();
var ne = { exports: {} }, $ = {};
/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var Ie;
function $r() {
  if (Ie) return $;
  Ie = 1;
  var g = Me, s = Symbol.for("react.element"), o = Symbol.for("react.fragment"), i = Object.prototype.hasOwnProperty, u = g.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner, y = { key: !0, ref: !0, __self: !0, __source: !0 };
  function h(j, v, R) {
    var d, p = {}, C = null, S = null;
    R !== void 0 && (C = "" + R), v.key !== void 0 && (C = "" + v.key), v.ref !== void 0 && (S = v.ref);
    for (d in v) i.call(v, d) && !y.hasOwnProperty(d) && (p[d] = v[d]);
    if (j && j.defaultProps) for (d in v = j.defaultProps, v) p[d] === void 0 && (p[d] = v[d]);
    return { $$typeof: s, type: j, key: C, ref: S, props: p, _owner: u.current };
  }
  return $.Fragment = o, $.jsx = h, $.jsxs = h, $;
}
var B = {};
/**
 * @license React
 * react-jsx-runtime.development.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var Le;
function Br() {
  return Le || (Le = 1, process.env.NODE_ENV !== "production" && function() {
    var g = Me, s = Symbol.for("react.element"), o = Symbol.for("react.portal"), i = Symbol.for("react.fragment"), u = Symbol.for("react.strict_mode"), y = Symbol.for("react.profiler"), h = Symbol.for("react.provider"), j = Symbol.for("react.context"), v = Symbol.for("react.forward_ref"), R = Symbol.for("react.suspense"), d = Symbol.for("react.suspense_list"), p = Symbol.for("react.memo"), C = Symbol.for("react.lazy"), S = Symbol.for("react.offscreen"), E = Symbol.iterator, q = "@@iterator";
    function $e(e) {
      if (e === null || typeof e != "object")
        return null;
      var r = E && e[E] || e[q];
      return typeof r == "function" ? r : null;
    }
    var D = g.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED;
    function _(e) {
      {
        for (var r = arguments.length, n = new Array(r > 1 ? r - 1 : 0), a = 1; a < r; a++)
          n[a - 1] = arguments[a];
        Be("error", e, n);
      }
    }
    function Be(e, r, n) {
      {
        var a = D.ReactDebugCurrentFrame, f = a.getStackAddendum();
        f !== "" && (r += "%s", n = n.concat([f]));
        var m = n.map(function(l) {
          return String(l);
        });
        m.unshift("Warning: " + r), Function.prototype.apply.call(console[e], console, m);
      }
    }
    var We = !1, Ue = !1, Ye = !1, Ve = !1, Ke = !1, ae;
    ae = Symbol.for("react.module.reference");
    function ze(e) {
      return !!(typeof e == "string" || typeof e == "function" || e === i || e === y || Ke || e === u || e === R || e === d || Ve || e === S || We || Ue || Ye || typeof e == "object" && e !== null && (e.$$typeof === C || e.$$typeof === p || e.$$typeof === h || e.$$typeof === j || e.$$typeof === v || // This needs to include all possible module reference object
      // types supported by any Flight configuration anywhere since
      // we don't know which Flight build this will end up being used
      // with.
      e.$$typeof === ae || e.getModuleId !== void 0));
    }
    function qe(e, r, n) {
      var a = e.displayName;
      if (a)
        return a;
      var f = r.displayName || r.name || "";
      return f !== "" ? n + "(" + f + ")" : n;
    }
    function se(e) {
      return e.displayName || "Context";
    }
    function O(e) {
      if (e == null)
        return null;
      if (typeof e.tag == "number" && _("Received an unexpected object in getComponentNameFromType(). This is likely a bug in React. Please file an issue."), typeof e == "function")
        return e.displayName || e.name || null;
      if (typeof e == "string")
        return e;
      switch (e) {
        case i:
          return "Fragment";
        case o:
          return "Portal";
        case y:
          return "Profiler";
        case u:
          return "StrictMode";
        case R:
          return "Suspense";
        case d:
          return "SuspenseList";
      }
      if (typeof e == "object")
        switch (e.$$typeof) {
          case j:
            var r = e;
            return se(r) + ".Consumer";
          case h:
            var n = e;
            return se(n._context) + ".Provider";
          case v:
            return qe(e, e.render, "ForwardRef");
          case p:
            var a = e.displayName || null;
            return a !== null ? a : O(e.type) || "Memo";
          case C: {
            var f = e, m = f._payload, l = f._init;
            try {
              return O(l(m));
            } catch {
              return null;
            }
          }
        }
      return null;
    }
    var P = Object.assign, L = 0, ie, oe, ce, le, ue, fe, de;
    function me() {
    }
    me.__reactDisabledLog = !0;
    function Ge() {
      {
        if (L === 0) {
          ie = console.log, oe = console.info, ce = console.warn, le = console.error, ue = console.group, fe = console.groupCollapsed, de = console.groupEnd;
          var e = {
            configurable: !0,
            enumerable: !0,
            value: me,
            writable: !0
          };
          Object.defineProperties(console, {
            info: e,
            log: e,
            warn: e,
            error: e,
            group: e,
            groupCollapsed: e,
            groupEnd: e
          });
        }
        L++;
      }
    }
    function Je() {
      {
        if (L--, L === 0) {
          var e = {
            configurable: !0,
            enumerable: !0,
            writable: !0
          };
          Object.defineProperties(console, {
            log: P({}, e, {
              value: ie
            }),
            info: P({}, e, {
              value: oe
            }),
            warn: P({}, e, {
              value: ce
            }),
            error: P({}, e, {
              value: le
            }),
            group: P({}, e, {
              value: ue
            }),
            groupCollapsed: P({}, e, {
              value: fe
            }),
            groupEnd: P({}, e, {
              value: de
            })
          });
        }
        L < 0 && _("disabledDepth fell below zero. This is a bug in React. Please file an issue.");
      }
    }
    var G = D.ReactCurrentDispatcher, J;
    function W(e, r, n) {
      {
        if (J === void 0)
          try {
            throw Error();
          } catch (f) {
            var a = f.stack.trim().match(/\n( *(at )?)/);
            J = a && a[1] || "";
          }
        return `
` + J + e;
      }
    }
    var X = !1, U;
    {
      var Xe = typeof WeakMap == "function" ? WeakMap : Map;
      U = new Xe();
    }
    function he(e, r) {
      if (!e || X)
        return "";
      {
        var n = U.get(e);
        if (n !== void 0)
          return n;
      }
      var a;
      X = !0;
      var f = Error.prepareStackTrace;
      Error.prepareStackTrace = void 0;
      var m;
      m = G.current, G.current = null, Ge();
      try {
        if (r) {
          var l = function() {
            throw Error();
          };
          if (Object.defineProperty(l.prototype, "props", {
            set: function() {
              throw Error();
            }
          }), typeof Reflect == "object" && Reflect.construct) {
            try {
              Reflect.construct(l, []);
            } catch (T) {
              a = T;
            }
            Reflect.construct(e, [], l);
          } else {
            try {
              l.call();
            } catch (T) {
              a = T;
            }
            e.call(l.prototype);
          }
        } else {
          try {
            throw Error();
          } catch (T) {
            a = T;
          }
          e();
        }
      } catch (T) {
        if (T && a && typeof T.stack == "string") {
          for (var c = T.stack.split(`
`), w = a.stack.split(`
`), x = c.length - 1, b = w.length - 1; x >= 1 && b >= 0 && c[x] !== w[b]; )
            b--;
          for (; x >= 1 && b >= 0; x--, b--)
            if (c[x] !== w[b]) {
              if (x !== 1 || b !== 1)
                do
                  if (x--, b--, b < 0 || c[x] !== w[b]) {
                    var k = `
` + c[x].replace(" at new ", " at ");
                    return e.displayName && k.includes("<anonymous>") && (k = k.replace("<anonymous>", e.displayName)), typeof e == "function" && U.set(e, k), k;
                  }
                while (x >= 1 && b >= 0);
              break;
            }
        }
      } finally {
        X = !1, G.current = m, Je(), Error.prepareStackTrace = f;
      }
      var I = e ? e.displayName || e.name : "", N = I ? W(I) : "";
      return typeof e == "function" && U.set(e, N), N;
    }
    function He(e, r, n) {
      return he(e, !1);
    }
    function Ze(e) {
      var r = e.prototype;
      return !!(r && r.isReactComponent);
    }
    function Y(e, r, n) {
      if (e == null)
        return "";
      if (typeof e == "function")
        return he(e, Ze(e));
      if (typeof e == "string")
        return W(e);
      switch (e) {
        case R:
          return W("Suspense");
        case d:
          return W("SuspenseList");
      }
      if (typeof e == "object")
        switch (e.$$typeof) {
          case v:
            return He(e.render);
          case p:
            return Y(e.type, r, n);
          case C: {
            var a = e, f = a._payload, m = a._init;
            try {
              return Y(m(f), r, n);
            } catch {
            }
          }
        }
      return "";
    }
    var M = Object.prototype.hasOwnProperty, ve = {}, pe = D.ReactDebugCurrentFrame;
    function V(e) {
      if (e) {
        var r = e._owner, n = Y(e.type, e._source, r ? r.type : null);
        pe.setExtraStackFrame(n);
      } else
        pe.setExtraStackFrame(null);
    }
    function Qe(e, r, n, a, f) {
      {
        var m = Function.call.bind(M);
        for (var l in e)
          if (m(e, l)) {
            var c = void 0;
            try {
              if (typeof e[l] != "function") {
                var w = Error((a || "React class") + ": " + n + " type `" + l + "` is invalid; it must be a function, usually from the `prop-types` package, but received `" + typeof e[l] + "`.This often happens because of typos such as `PropTypes.function` instead of `PropTypes.func`.");
                throw w.name = "Invariant Violation", w;
              }
              c = e[l](r, l, a, n, null, "SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED");
            } catch (x) {
              c = x;
            }
            c && !(c instanceof Error) && (V(f), _("%s: type specification of %s `%s` is invalid; the type checker function must return `null` or an `Error` but returned a %s. You may have forgotten to pass an argument to the type checker creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and shape all require an argument).", a || "React class", n, l, typeof c), V(null)), c instanceof Error && !(c.message in ve) && (ve[c.message] = !0, V(f), _("Failed %s type: %s", n, c.message), V(null));
          }
      }
    }
    var er = Array.isArray;
    function H(e) {
      return er(e);
    }
    function rr(e) {
      {
        var r = typeof Symbol == "function" && Symbol.toStringTag, n = r && e[Symbol.toStringTag] || e.constructor.name || "Object";
        return n;
      }
    }
    function tr(e) {
      try {
        return xe(e), !1;
      } catch {
        return !0;
      }
    }
    function xe(e) {
      return "" + e;
    }
    function be(e) {
      if (tr(e))
        return _("The provided key is an unsupported type %s. This value must be coerced to a string before before using it here.", rr(e)), xe(e);
    }
    var ge = D.ReactCurrentOwner, nr = {
      key: !0,
      ref: !0,
      __self: !0,
      __source: !0
    }, ye, je;
    function ar(e) {
      if (M.call(e, "ref")) {
        var r = Object.getOwnPropertyDescriptor(e, "ref").get;
        if (r && r.isReactWarning)
          return !1;
      }
      return e.ref !== void 0;
    }
    function sr(e) {
      if (M.call(e, "key")) {
        var r = Object.getOwnPropertyDescriptor(e, "key").get;
        if (r && r.isReactWarning)
          return !1;
      }
      return e.key !== void 0;
    }
    function ir(e, r) {
      typeof e.ref == "string" && ge.current;
    }
    function or(e, r) {
      {
        var n = function() {
          ye || (ye = !0, _("%s: `key` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://reactjs.org/link/special-props)", r));
        };
        n.isReactWarning = !0, Object.defineProperty(e, "key", {
          get: n,
          configurable: !0
        });
      }
    }
    function cr(e, r) {
      {
        var n = function() {
          je || (je = !0, _("%s: `ref` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://reactjs.org/link/special-props)", r));
        };
        n.isReactWarning = !0, Object.defineProperty(e, "ref", {
          get: n,
          configurable: !0
        });
      }
    }
    var lr = function(e, r, n, a, f, m, l) {
      var c = {
        // This tag allows us to uniquely identify this as a React Element
        $$typeof: s,
        // Built-in properties that belong on the element
        type: e,
        key: r,
        ref: n,
        props: l,
        // Record the component responsible for creating this element.
        _owner: m
      };
      return c._store = {}, Object.defineProperty(c._store, "validated", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: !1
      }), Object.defineProperty(c, "_self", {
        configurable: !1,
        enumerable: !1,
        writable: !1,
        value: a
      }), Object.defineProperty(c, "_source", {
        configurable: !1,
        enumerable: !1,
        writable: !1,
        value: f
      }), Object.freeze && (Object.freeze(c.props), Object.freeze(c)), c;
    };
    function ur(e, r, n, a, f) {
      {
        var m, l = {}, c = null, w = null;
        n !== void 0 && (be(n), c = "" + n), sr(r) && (be(r.key), c = "" + r.key), ar(r) && (w = r.ref, ir(r, f));
        for (m in r)
          M.call(r, m) && !nr.hasOwnProperty(m) && (l[m] = r[m]);
        if (e && e.defaultProps) {
          var x = e.defaultProps;
          for (m in x)
            l[m] === void 0 && (l[m] = x[m]);
        }
        if (c || w) {
          var b = typeof e == "function" ? e.displayName || e.name || "Unknown" : e;
          c && or(l, b), w && cr(l, b);
        }
        return lr(e, c, w, f, a, ge.current, l);
      }
    }
    var Z = D.ReactCurrentOwner, Ee = D.ReactDebugCurrentFrame;
    function A(e) {
      if (e) {
        var r = e._owner, n = Y(e.type, e._source, r ? r.type : null);
        Ee.setExtraStackFrame(n);
      } else
        Ee.setExtraStackFrame(null);
    }
    var Q;
    Q = !1;
    function ee(e) {
      return typeof e == "object" && e !== null && e.$$typeof === s;
    }
    function _e() {
      {
        if (Z.current) {
          var e = O(Z.current.type);
          if (e)
            return `

Check the render method of \`` + e + "`.";
        }
        return "";
      }
    }
    function fr(e) {
      return "";
    }
    var we = {};
    function dr(e) {
      {
        var r = _e();
        if (!r) {
          var n = typeof e == "string" ? e : e.displayName || e.name;
          n && (r = `

Check the top-level render call using <` + n + ">.");
        }
        return r;
      }
    }
    function Re(e, r) {
      {
        if (!e._store || e._store.validated || e.key != null)
          return;
        e._store.validated = !0;
        var n = dr(r);
        if (we[n])
          return;
        we[n] = !0;
        var a = "";
        e && e._owner && e._owner !== Z.current && (a = " It was passed a child from " + O(e._owner.type) + "."), A(e), _('Each child in a list should have a unique "key" prop.%s%s See https://reactjs.org/link/warning-keys for more information.', n, a), A(null);
      }
    }
    function Ce(e, r) {
      {
        if (typeof e != "object")
          return;
        if (H(e))
          for (var n = 0; n < e.length; n++) {
            var a = e[n];
            ee(a) && Re(a, r);
          }
        else if (ee(e))
          e._store && (e._store.validated = !0);
        else if (e) {
          var f = $e(e);
          if (typeof f == "function" && f !== e.entries)
            for (var m = f.call(e), l; !(l = m.next()).done; )
              ee(l.value) && Re(l.value, r);
        }
      }
    }
    function mr(e) {
      {
        var r = e.type;
        if (r == null || typeof r == "string")
          return;
        var n;
        if (typeof r == "function")
          n = r.propTypes;
        else if (typeof r == "object" && (r.$$typeof === v || // Note: Memo only checks outer props here.
        // Inner props are checked in the reconciler.
        r.$$typeof === p))
          n = r.propTypes;
        else
          return;
        if (n) {
          var a = O(r);
          Qe(n, e.props, "prop", a, e);
        } else if (r.PropTypes !== void 0 && !Q) {
          Q = !0;
          var f = O(r);
          _("Component %s declared `PropTypes` instead of `propTypes`. Did you misspell the property assignment?", f || "Unknown");
        }
        typeof r.getDefaultProps == "function" && !r.getDefaultProps.isReactClassApproved && _("getDefaultProps is only used on classic React.createClass definitions. Use a static property named `defaultProps` instead.");
      }
    }
    function hr(e) {
      {
        for (var r = Object.keys(e.props), n = 0; n < r.length; n++) {
          var a = r[n];
          if (a !== "children" && a !== "key") {
            A(e), _("Invalid prop `%s` supplied to `React.Fragment`. React.Fragment can only have `key` and `children` props.", a), A(null);
            break;
          }
        }
        e.ref !== null && (A(e), _("Invalid attribute `ref` supplied to `React.Fragment`."), A(null));
      }
    }
    var Se = {};
    function Te(e, r, n, a, f, m) {
      {
        var l = ze(e);
        if (!l) {
          var c = "";
          (e === void 0 || typeof e == "object" && e !== null && Object.keys(e).length === 0) && (c += " You likely forgot to export your component from the file it's defined in, or you might have mixed up default and named imports.");
          var w = fr();
          w ? c += w : c += _e();
          var x;
          e === null ? x = "null" : H(e) ? x = "array" : e !== void 0 && e.$$typeof === s ? (x = "<" + (O(e.type) || "Unknown") + " />", c = " Did you accidentally export a JSX literal instead of a component?") : x = typeof e, _("React.jsx: type is invalid -- expected a string (for built-in components) or a class/function (for composite components) but got: %s.%s", x, c);
        }
        var b = ur(e, r, n, f, m);
        if (b == null)
          return b;
        if (l) {
          var k = r.children;
          if (k !== void 0)
            if (a)
              if (H(k)) {
                for (var I = 0; I < k.length; I++)
                  Ce(k[I], e);
                Object.freeze && Object.freeze(k);
              } else
                _("React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead.");
            else
              Ce(k, e);
        }
        if (M.call(r, "key")) {
          var N = O(e), T = Object.keys(r).filter(function(yr) {
            return yr !== "key";
          }), re = T.length > 0 ? "{key: someKey, " + T.join(": ..., ") + ": ...}" : "{key: someKey}";
          if (!Se[N + re]) {
            var gr = T.length > 0 ? "{" + T.join(": ..., ") + ": ...}" : "{}";
            _(`A props object containing a "key" prop is being spread into JSX:
  let props = %s;
  <%s {...props} />
React keys must be passed directly to JSX without using spread:
  let props = %s;
  <%s key={someKey} {...props} />`, re, N, gr, N), Se[N + re] = !0;
          }
        }
        return e === i ? hr(b) : mr(b), b;
      }
    }
    function vr(e, r, n) {
      return Te(e, r, n, !0);
    }
    function pr(e, r, n) {
      return Te(e, r, n, !1);
    }
    var xr = pr, br = vr;
    B.Fragment = i, B.jsx = xr, B.jsxs = br;
  }()), B;
}
process.env.NODE_ENV === "production" ? ne.exports = $r() : ne.exports = Br();
var t = ne.exports;
const Jr = ({
  title: g,
  subtitle: s,
  children: o,
  loading: i = !1,
  error: u,
  className: y,
  onRefresh: h,
  onExport: j,
  onFullscreen: v,
  actions: R,
  height: d = 300
}) => {
  const [p, C] = wr(!1), S = async () => {
    if (!(!h || p)) {
      C(!0);
      try {
        await h();
      } finally {
        C(!1);
      }
    }
  }, E = (...q) => q.filter(Boolean).join(" ");
  return /* @__PURE__ */ t.jsxs("div", { className: E(
    "bg-bg-elevated border border-border-primary rounded-lg shadow-card",
    "overflow-hidden",
    y
  ), children: [
    /* @__PURE__ */ t.jsx("div", { className: "px-6 py-4 border-b border-border-secondary", children: /* @__PURE__ */ t.jsxs("div", { className: "flex items-center justify-between", children: [
      /* @__PURE__ */ t.jsxs("div", { className: "flex-1 min-w-0", children: [
        /* @__PURE__ */ t.jsx("h3", { className: "text-lg font-semibold text-text-primary truncate", children: g }),
        s && /* @__PURE__ */ t.jsx("p", { className: "text-sm text-text-tertiary mt-1", children: s })
      ] }),
      /* @__PURE__ */ t.jsxs("div", { className: "flex items-center space-x-2 ml-4", children: [
        R,
        h && /* @__PURE__ */ t.jsx(
          "button",
          {
            onClick: S,
            disabled: p,
            className: E(
              "p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md",
              "transition-colors duration-200",
              p ? "animate-spin" : ""
            ),
            title: "刷新数据",
            children: /* @__PURE__ */ t.jsx(Rr, { className: "w-4 h-4" })
          }
        ),
        j && /* @__PURE__ */ t.jsx(
          "button",
          {
            onClick: j,
            className: "p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200",
            title: "导出数据",
            children: /* @__PURE__ */ t.jsx(Cr, { className: "w-4 h-4" })
          }
        ),
        v && /* @__PURE__ */ t.jsx(
          "button",
          {
            onClick: v,
            className: "p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200",
            title: "全屏查看",
            children: /* @__PURE__ */ t.jsx(Sr, { className: "w-4 h-4" })
          }
        ),
        /* @__PURE__ */ t.jsx("button", { className: "p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200", children: /* @__PURE__ */ t.jsx(Tr, { className: "w-4 h-4" }) })
      ] })
    ] }) }),
    /* @__PURE__ */ t.jsxs(
      "div",
      {
        className: "relative",
        style: { height: typeof d == "number" ? `${d}px` : d },
        children: [
          i ? /* @__PURE__ */ t.jsx("div", { className: "absolute inset-0 flex items-center justify-center", children: /* @__PURE__ */ t.jsxs("div", { className: "flex flex-col items-center space-y-3", children: [
            /* @__PURE__ */ t.jsx("div", { className: "animate-spin rounded-full h-8 w-8 border-2 border-accent-primary border-t-transparent" }),
            /* @__PURE__ */ t.jsx("p", { className: "text-sm text-text-tertiary", children: "加载中..." })
          ] }) }) : u ? /* @__PURE__ */ t.jsx("div", { className: "absolute inset-0 flex items-center justify-center", children: /* @__PURE__ */ t.jsxs("div", { className: "text-center", children: [
            /* @__PURE__ */ t.jsx("div", { className: "w-12 h-12 mx-auto mb-4 text-status-error", children: /* @__PURE__ */ t.jsx("svg", { viewBox: "0 0 24 24", fill: "currentColor", children: /* @__PURE__ */ t.jsx("path", { d: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" }) }) }),
            /* @__PURE__ */ t.jsx("p", { className: "text-sm text-status-error font-medium mb-2", children: "数据加载失败" }),
            /* @__PURE__ */ t.jsx("p", { className: "text-xs text-text-tertiary mb-4", children: u }),
            h && /* @__PURE__ */ t.jsx(
              "button",
              {
                onClick: S,
                className: "text-sm text-accent-primary hover:text-accent-hover font-medium",
                children: "重新加载"
              }
            )
          ] }) }) : /* @__PURE__ */ t.jsx("div", { className: "h-full w-full p-6", children: o }),
          p && !i && /* @__PURE__ */ t.jsx("div", { className: "absolute inset-0 bg-bg-primary bg-opacity-50 flex items-center justify-center", children: /* @__PURE__ */ t.jsx("div", { className: "animate-spin rounded-full h-6 w-6 border-2 border-accent-primary border-t-transparent" }) })
        ]
      }
    )
  ] });
}, Xr = ({
  data: g,
  variant: s = "area",
  showGrid: o = !0,
  animate: i = !0,
  height: u = 300
}) => {
  const y = (d) => Fe(new Date(d), "MM/dd"), h = (d) => d >= 1e6 ? `${(d / 1e6).toFixed(1)}M` : d >= 1e3 ? `${(d / 1e3).toFixed(1)}K` : d.toString(), j = ({ active: d, payload: p, label: C }) => {
    if (d && p && p.length) {
      const S = p[0].payload;
      return /* @__PURE__ */ t.jsxs("div", { className: "bg-bg-elevated border border-border-primary rounded-lg shadow-modal p-3", children: [
        /* @__PURE__ */ t.jsx("p", { className: "text-sm font-medium text-text-primary mb-1", children: Fe(new Date(C), "yyyy年MM月dd日") }),
        /* @__PURE__ */ t.jsxs("div", { className: "flex items-center", children: [
          /* @__PURE__ */ t.jsx(
            "div",
            {
              className: "w-3 h-3 rounded-full mr-2",
              style: { backgroundColor: "#00B96B" }
            }
          ),
          /* @__PURE__ */ t.jsx("span", { className: "text-sm text-text-secondary", children: "用户数：" }),
          /* @__PURE__ */ t.jsx("span", { className: "text-sm font-semibold text-text-primary ml-1", children: p[0].value.toLocaleString() })
        ] }),
        S.label && /* @__PURE__ */ t.jsx("p", { className: "text-xs text-text-tertiary mt-1", children: S.label })
      ] });
    }
    return null;
  }, v = "userGrowthGradient", R = {
    data: g,
    margin: { top: 20, right: 30, left: 20, bottom: 5 }
  };
  return /* @__PURE__ */ t.jsx(Nr, { width: "100%", height: u, children: s === "area" ? /* @__PURE__ */ t.jsxs(Fr, { ...R, children: [
    /* @__PURE__ */ t.jsx("defs", { children: /* @__PURE__ */ t.jsxs("linearGradient", { id: v, x1: "0", y1: "0", x2: "0", y2: "1", children: [
      /* @__PURE__ */ t.jsx("stop", { offset: "5%", stopColor: "#00B96B", stopOpacity: 0.3 }),
      /* @__PURE__ */ t.jsx("stop", { offset: "95%", stopColor: "#00B96B", stopOpacity: 0 })
    ] }) }),
    o && /* @__PURE__ */ t.jsx(
      ke,
      {
        strokeDasharray: "3 3",
        stroke: "#E5E6EB",
        strokeOpacity: 0.5
      }
    ),
    /* @__PURE__ */ t.jsx(
      Oe,
      {
        dataKey: "timestamp",
        tickFormatter: y,
        axisLine: !1,
        tickLine: !1,
        tick: {
          fill: "#8F959E",
          fontSize: 12,
          fontFamily: "Inter"
        },
        dy: 10
      }
    ),
    /* @__PURE__ */ t.jsx(
      Pe,
      {
        tickFormatter: h,
        axisLine: !1,
        tickLine: !1,
        tick: {
          fill: "#8F959E",
          fontSize: 12,
          fontFamily: "Inter"
        },
        width: 60
      }
    ),
    /* @__PURE__ */ t.jsx(Ne, { content: /* @__PURE__ */ t.jsx(j, {}) }),
    /* @__PURE__ */ t.jsx(
      Dr,
      {
        type: "monotone",
        dataKey: "value",
        stroke: "#00B96B",
        strokeWidth: 3,
        fill: `url(#${v})`,
        dot: !1,
        activeDot: {
          r: 6,
          fill: "#00B96B",
          strokeWidth: 2,
          stroke: "#ffffff"
        },
        animationDuration: i ? 1e3 : 0,
        animationEasing: "ease-out"
      }
    )
  ] }) : /* @__PURE__ */ t.jsxs(Ar, { ...R, children: [
    o && /* @__PURE__ */ t.jsx(
      ke,
      {
        strokeDasharray: "3 3",
        stroke: "#E5E6EB",
        strokeOpacity: 0.5
      }
    ),
    /* @__PURE__ */ t.jsx(
      Oe,
      {
        dataKey: "timestamp",
        tickFormatter: y,
        axisLine: !1,
        tickLine: !1,
        tick: {
          fill: "#8F959E",
          fontSize: 12,
          fontFamily: "Inter"
        }
      }
    ),
    /* @__PURE__ */ t.jsx(
      Pe,
      {
        tickFormatter: h,
        axisLine: !1,
        tickLine: !1,
        tick: {
          fill: "#8F959E",
          fontSize: 12,
          fontFamily: "Inter"
        },
        width: 60
      }
    ),
    /* @__PURE__ */ t.jsx(Ne, { content: /* @__PURE__ */ t.jsx(j, {}) }),
    /* @__PURE__ */ t.jsx(
      Ir,
      {
        type: "monotone",
        dataKey: "value",
        stroke: "#00B96B",
        strokeWidth: 3,
        dot: !1,
        activeDot: {
          r: 6,
          fill: "#00B96B",
          strokeWidth: 2,
          stroke: "#ffffff"
        },
        animationDuration: i ? 1e3 : 0,
        animationEasing: "ease-out"
      }
    )
  ] }) });
}, Hr = ({
  title: g,
  value: s,
  change: o,
  trend: i = "neutral",
  suffix: u = "",
  prefix: y = "",
  icon: h,
  loading: j = !1,
  className: v,
  onClick: R
}) => {
  const d = {
    up: "text-status-success",
    down: "text-status-error",
    neutral: "text-text-tertiary"
  }, p = {
    up: Pr,
    down: Or,
    neutral: kr
  }[i], C = (E) => typeof E == "number" ? E >= 1e6 ? `${(E / 1e6).toFixed(1)}M` : E >= 1e3 ? `${(E / 1e3).toFixed(1)}K` : E.toLocaleString() : E.toString(), S = (...E) => E.filter(Boolean).join(" ");
  return j ? /* @__PURE__ */ t.jsxs("div", { className: S(
    "bg-bg-elevated border border-border-primary rounded-lg p-6 shadow-card",
    "animate-pulse",
    v
  ), children: [
    /* @__PURE__ */ t.jsxs("div", { className: "flex items-center justify-between mb-2", children: [
      /* @__PURE__ */ t.jsx("div", { className: "h-4 bg-bg-tertiary rounded w-24" }),
      h && /* @__PURE__ */ t.jsx("div", { className: "h-5 w-5 bg-bg-tertiary rounded" })
    ] }),
    /* @__PURE__ */ t.jsx("div", { className: "h-8 bg-bg-tertiary rounded w-16 mb-2" }),
    /* @__PURE__ */ t.jsx("div", { className: "h-4 bg-bg-tertiary rounded w-20" })
  ] }) : /* @__PURE__ */ t.jsxs(
    "div",
    {
      className: S(
        "bg-bg-elevated border border-border-primary rounded-lg p-6 shadow-card",
        "transition-all duration-200",
        "hover:shadow-hover hover:border-border-focus",
        R && "cursor-pointer",
        v
      ),
      onClick: R,
      children: [
        /* @__PURE__ */ t.jsxs("div", { className: "flex items-center justify-between mb-2", children: [
          /* @__PURE__ */ t.jsx("h3", { className: "text-sm font-medium text-text-secondary", children: g }),
          h && /* @__PURE__ */ t.jsx("div", { className: "flex-shrink-0 text-text-tertiary", children: h })
        ] }),
        /* @__PURE__ */ t.jsx("div", { className: "mb-2", children: /* @__PURE__ */ t.jsxs("span", { className: "text-3xl font-bold text-text-primary", children: [
          y,
          C(s),
          u
        ] }) }),
        o && /* @__PURE__ */ t.jsxs("div", { className: S(
          "flex items-center text-sm",
          d[i]
        ), children: [
          /* @__PURE__ */ t.jsx(p, { className: "w-4 h-4 mr-1" }),
          /* @__PURE__ */ t.jsx("span", { className: "font-medium", children: o }),
          /* @__PURE__ */ t.jsx("span", { className: "ml-1 text-text-tertiary", children: "vs 昨日" })
        ] })
      ]
    }
  );
};
export {
  Jr as ChartContainer,
  Hr as MetricCard,
  Mr as RealtimeMetricsService,
  z as SupabaseDataService,
  Xr as UserGrowthChart,
  qr as dataService,
  Gr as metricsService,
  Lr as supabase
};
//# sourceMappingURL=xingqu-shared.es.js.map
