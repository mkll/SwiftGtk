//
//  Container.swift
//  Gtk
//
//  Created by Rene Hexel on 29/4/17.
//  Copyright © 2017 Rene Hexel.  All rights reserved.
//
import CGLib
import CGtk
import GLib
import GLibObject
import GIO
import Cairo

public extension Container {
    /// Set a child widget property
    ///
    /// - Parameters:
    ///   - child: widget to set property for
    ///   - property: `ParamSpec` for property
    ///   - value: value to set
    /// - Returns: `true` if successful, `false` if value cannot be transformed
    @discardableResult
    public func set<W: WidgetProtocol, P: ParamSpecProtocol, V: ValueProtocol>(child: W, property: P, value: V) -> Bool {
        let container = ptr.withMemoryRebound(to: GtkContainer.self, capacity: 1) { $0 }
        let ptype = property.ptr.pointee.value_type
        let tmpValue = Value()
        _ = tmpValue.init_(gType: ptype)
        defer { tmpValue.unset() }
        guard value.transform(destValue: tmpValue) /* &&
             (property.paramValueValidate(value: tmpValue) ||
             (property.ptr.pointee.flags.rawValue & (ParamFlags.lax_validation)) != 0) */ else { return false }
        let paramID = property.ptr.pointee.param_id
        let widget = child.ptr.withMemoryRebound(to: GtkWidget.self, capacity: 1) { $0 }
        let typeClass = ContainerClassRef(raw: typeClassPeek(type: ptype))
        typeClass.ptr.pointee.set_child_property(container, widget, paramID, tmpValue.ptr, property.ptr)
        return true
    }
    public func set<W: WidgetProtocol, P: PropertyNameProtocol, V>(child widget: W, property: P, value: V) {
        guard let paramSpec = ParamSpecRef(name: property, from:_gtk_widget_child_property_pool) else {
            g_warning("\(#file): container class \(typeName) has no child property named \(property.rawValue)")
            return
        }
        let v = Value(value)
        set(child: widget, property: paramSpec, value: v)
    }
    /// Set the property of a child widget
    ///
    /// - Parameters:
    ///   - child: widget to set property for
    ///   - property: name of the property
    ///   - value: value to set
    public func set<W: WidgetProtocol, P: PropertyNameProtocol>(child widget: W, properties: [(P, Any)]) {
        let nq = widget.freeze(context: _gtk_widget_child_property_notify_context)
        defer { if let nq = nq { widget.thaw(queue: nq) } }
        for (p, v) in properties {
            set(child: widget, property: p, value: v)
        }
    }
    /// Set up a child widget with the given list of properties
    ///
    /// - Parameters:
    ///   - widget: child widget to set properties for
    ///   - properties: `PropertyName` / value pairs to set
    public func set<W: WidgetProtocol, P: PropertyNameProtocol>(child widget: W, properties ps: (P, Any)...) {
        set(child: widget, properties: ps)
    }
    /// Add a child widget with a given list of properties
    ///
    /// - Parameters:
    ///   - widget: child widget to add
    ///   - properties: `PropertyName` / value pairs of properties to set
    public func add<W: WidgetProtocol, P: PropertyNameProtocol>(_ widget: W, properties ps: (P, Any)...) {
        widget.freezeChildNotify() ; defer { widget.thawChildNotify() }
        emit(ContainerSignalName.add, widget.ptr)
        set(child: widget, properties: ps)
    }
    /// Add a child widget with a given property
    ///
    /// - Parameters:
    ///   - widget: child widget to add
    ///   - property: name of the property to set
    ///   - value: value of the property to set
    public func add<W: WidgetProtocol, P: PropertyNameProtocol, V>(_ widget: W, property p: P, value v: V) {
        widget.freezeChildNotify() ; defer { widget.thawChildNotify() }
        emit(ContainerSignalName.add, widget.ptr)
        set(child: widget, property: p, value: v)
    }
}
