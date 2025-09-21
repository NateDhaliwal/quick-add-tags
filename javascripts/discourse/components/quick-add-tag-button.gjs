import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

import { action } from "@ember/object";
import { service } from "@ember/service";

import { ajax } from "discourse/lib/ajax";
import { timeShortcuts } from "discourse/lib/time-shortcut";
import { inNDays } from "discourse/lib/time-utils";
import DButton from "discourse/components/d-button";

export default class QuickAddTagButton extends Component {
  @service currentUser;
  @service toasts;
  @service discovery;

  @tracked category = this.discovery;

  get shouldShow() {
    console.log(this.args.topic);
    console.log(this.category);
    const settingObj = settings.quick_add_tags_buttons;
    
    const canEdit = this.args.topic.canEditTags;

    // for (const settingButton in settingObj) {
    //   if (settingButton.categories.split("|").includes(this.args.topic.category_id)) {
    //   if (settings.auto_close_topic) {
    //     if (this.currentUser.moderator || this.currentUser.admin || this.currentUser.trust_level == 4) {
    //       return true;
    //     } else {
    //       return false;
    //     }
    //   } else {
    //     return canEdit;
    //   }
    // }
    return true;
  }

  @action
  async addTag() {
    const topic = this.args.topic;
    const currentTags = topic.tags;
    const settingTags = settings.quick_add_tags.split("|");
    let newTags = currentTags;

    settingTags.forEach((tag) => {
      if (!currentTags.includes(tag)) {
        newTags.push(tag);
      }
    });
    
    try {
      if (settings.auto_close_topic) {
        await ajax(`/t/${topic.id}/timer.json`, {
          type: "POST",
          data: {
            status_type: "close",
            time: settings.auto_close_topic_days * 24 // In hours, multiply by 24 to get days
          }
        });
      }
      await ajax(`/t/-/${topic.id}.json`, {
        type: "PUT",
        data: {
          tags: newTags,
          keep_existing_draft: true
        }
      }).then((response) => {
        this.toasts.success({
          duration: "short",
          data: {
            // eslint-disable-next-line no-undef
            message: I18n.t(themePrefix("added_tag_success_message")),
          },
        });
      });
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e);
      if (e.jqXHR.responseJSON.errors !== undefined) {
        const errors = e.jqXHR.responseJSON.errors;
        errors.forEach((error) => {
          this.toasts.error({
            duration: "short",
            data: {
              message: error
            },
          });
        });
      }
    }
  }

  <template>
    {{#if this.shouldShow}}
      <DButton
        @action={{this.addTag}}
        @icon="tag"
        @label={{themePrefix "quick_add_tag_button_text"}}
        @title={{themePrefix "quick_add_tag_button_title"}}
        class="btn-text"
      />
    {{/if}}
  </template>
}
