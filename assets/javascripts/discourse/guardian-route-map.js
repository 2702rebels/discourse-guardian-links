export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("guardian-links", { path: "/guardian-links" });
  },
};
