//! In-memory todo store, safe to share across connections.
const std = @import("std");
const Io = std.Io;

pub const Todo = struct {
    id: u32,
    title: []const u8,
    done: bool,
    /// Resource URL, e.g. "/todos/3". Used by the row's PATCH and DELETE.
    path: []const u8,
};

gpa: std.mem.Allocator,
mutex: Io.Mutex = .init,
items: std.ArrayList(Todo) = .empty,
next_id: u32 = 1,

const Store = @This();

/// Copies all todos into `arena`, so rendering never races with writers.
pub fn list(s: *Store, io: Io, arena: std.mem.Allocator) ![]Todo {
    try s.mutex.lock(io);
    defer s.mutex.unlock(io);
    const out = try arena.dupe(Todo, s.items.items);
    for (out) |*t| t.* = try copy(arena, t.*);
    return out;
}

pub fn add(s: *Store, io: Io, arena: std.mem.Allocator, title: []const u8) !Todo {
    try s.mutex.lock(io);
    defer s.mutex.unlock(io);
    const id = s.next_id;
    const t: Todo = .{
        .id = id,
        .title = try s.gpa.dupe(u8, title),
        .done = false,
        .path = try s.gpa.print("/todos/{d}", .{id}),
    };
    try s.items.append(s.gpa, t);
    s.next_id += 1;
    return copy(arena, t);
}

/// Flips `done`; null when the id does not exist.
pub fn toggle(s: *Store, io: Io, arena: std.mem.Allocator, id: u32) !?Todo {
    try s.mutex.lock(io);
    defer s.mutex.unlock(io);
    for (s.items.items) |*t| if (t.id == id) {
        t.done = !t.done;
        return try copy(arena, t.*);
    };
    return null;
}

pub fn remove(s: *Store, io: Io, id: u32) !bool {
    try s.mutex.lock(io);
    defer s.mutex.unlock(io);
    for (s.items.items, 0..) |t, i| if (t.id == id) {
        s.gpa.free(t.title);
        s.gpa.free(t.path);
        _ = s.items.orderedRemove(i);
        return true;
    };
    return false;
}

pub fn remaining(todos: []const Todo) usize {
    var n: usize = 0;
    for (todos) |t| n += @intFromBool(!t.done);
    return n;
}

fn copy(arena: std.mem.Allocator, t: Todo) !Todo {
    return .{ .id = t.id, .done = t.done, .title = try arena.dupe(u8, t.title), .path = try arena.dupe(u8, t.path) };
}

test "add, toggle, remove" {
    var s: Store = .{ .gpa = std.testing.allocator };
    defer {
        for (s.items.items) |t| {
            s.gpa.free(t.title);
            s.gpa.free(t.path);
        }
        s.items.deinit(s.gpa);
    }
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const io = std.testing.io;
    const a = try s.add(io, arena.allocator(), "milk");
    _ = try s.add(io, arena.allocator(), "eggs");
    try std.testing.expect((try s.toggle(io, arena.allocator(), a.id)).?.done);
    try std.testing.expectEqual(1, remaining(try s.list(io, arena.allocator())));
    try std.testing.expect(try s.remove(io, a.id));
    try std.testing.expect(!try s.remove(io, a.id));
    try std.testing.expect(try s.toggle(io, arena.allocator(), 99) == null);
}
