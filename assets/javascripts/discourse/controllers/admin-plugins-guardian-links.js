import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";

export default class AdminPluginsGuardianLinksController extends Controller {
  @tracked links = [];
  @tracked parentUsername = "";
  @tracked studentUsername = "";
  @tracked relationshipType = "parent";
  @tracked isSaving = false;

  @action
  changeRelationshipType(event) {
    this.relationshipType = event.target.value;
  }

  @action
  async createLink() {
    if (!this.parentUsername || !this.studentUsername) {
      return;
    }

    this.isSaving = true;
    try {
      const response = await ajax("/admin/plugins/guardian-links/links.json", {
        type: "POST",
        data: {
          parent_username: this.parentUsername,
          student_username: this.studentUsername,
          relationship_type: this.relationshipType || "parent",
        },
      });

      if (response && response.guardian_link) {
        this.links = [response.guardian_link, ...this.links];
        this.parentUsername = "";
        this.studentUsername = "";
      }
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async deleteLink(link) {
    if (!confirm(I18n.t("js.guardian_links.confirm_delete"))) {
      return;
    }

    try {
      await ajax(`/admin/plugins/guardian-links/links/${link.id}.json`, {
        type: "DELETE",
      });
      this.links = this.links.filter((l) => l.id !== link.id);
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
