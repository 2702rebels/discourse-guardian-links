import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";

export default class AdminPluginsGuardianLinksController extends Controller {
  @action
  async createLink() {
    if (!this.parentUsername || !this.studentUsername) {
      return;
    }

    this.set("isSaving", true);
    try {
      const response = await ajax("/admin/plugins/guardian-links.json", {
        type: "POST",
        data: {
          parent_username: this.parentUsername,
          student_username: this.studentUsername,
          relationship_type: this.relationshipType || "parent",
        },
      });

      if (response && response.guardian_link) {
        this.links.unshiftObject(response.guardian_link);
        this.set("parentUsername", "");
        this.set("studentUsername", "");
      }
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.set("isSaving", false);
    }
  }

  @action
  async deleteLink(link) {
    if (!confirm(I18n.t("js.guardian_links.confirm_delete"))) {
      return;
    }

    try {
      await ajax(`/admin/plugins/guardian-links/${link.id}.json`, {
        type: "DELETE",
      });
      this.links.removeObject(link);
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
