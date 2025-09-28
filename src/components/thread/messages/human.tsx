import { useStreamContext } from "@/providers/Stream";
import { Message } from "@langchain/langgraph-sdk";
import { useState } from "react";
import { getContentString } from "../utils";
import { cn } from "@/lib/utils";
import { Textarea } from "@/components/ui/textarea";
import { BranchSwitcher, CommandBar } from "./shared";
import { MultimodalPreview } from "@/components/thread/MultimodalPreview";
import { isBase64ContentBlock } from "@/lib/multimodal-utils";

function EditableContent({
  value,
  setValue,
  onSubmit,
}: {
  value: string;
  setValue: React.Dispatch<React.SetStateAction<string>>;
  onSubmit: () => void;
}) {
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
      e.preventDefault();
      onSubmit();
    }
  };

  return (
    <Textarea
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onKeyDown={handleKeyDown}
      className="focus-visible:ring-0"
    />
  );
}

export function HumanMessage({
  message,
  isLoading,
}: {
  message: Message;
  isLoading: boolean;
}) {
  const thread = useStreamContext();
  const meta = thread.getMessagesMetadata(message);
  const parentCheckpoint = meta?.firstSeenState?.parent_checkpoint;

  const [isEditing, setIsEditing] = useState(false);
  const [value, setValue] = useState("");
  const contentString = getContentString(message.content);

  const handleSubmitEdit = () => {
    setIsEditing(false);

    const newMessage: Message = { type: "human", content: value };
    thread.submit(
      { messages: [newMessage] },
      {
        checkpoint: parentCheckpoint,
        streamMode: ["values"],
        streamSubgraphs: true,
        streamResumable: true,
        optimisticValues: (prev) => {
          const values = meta?.firstSeenState?.values;
          if (!values) return prev;

          return {
            ...values,
            messages: [...(values.messages ?? []), newMessage],
          };
        },
      },
    );
  };

  return (
    <div
      className={cn(
        "group message-group human-group w-full",
        isEditing && "editing",
      )}
    >
      <div className="message-container">
        <div className="flex items-start gap-4">
          {!isEditing && (
            <div className="flex-shrink-0">
              <div className="message-avatar human-avatar">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd"/>
                </svg>
              </div>
            </div>
          )}
          <div className={cn("flex flex-col gap-3 flex-1 min-w-0", isEditing && "w-full")}>
            {isEditing ? (
              <EditableContent
                value={value}
                setValue={setValue}
                onSubmit={handleSubmitEdit}
              />
            ) : (
              <div className="flex flex-col gap-3">
                {/* Render images and files if no text */}
                {Array.isArray(message.content) && message.content.length > 0 && (
                  <div className="flex flex-wrap items-start gap-2">
                    {message.content.reduce<React.ReactNode[]>(
                      (acc, block, idx) => {
                        if (isBase64ContentBlock(block)) {
                          acc.push(
                            <MultimodalPreview
                              key={idx}
                              block={block}
                              size="md"
                            />,
                          );
                        }
                        return acc;
                      },
                      [],
                    )}
                  </div>
                )}
                {/* Render text if present, otherwise fallback to file/image name */}
                {contentString ? (
                  <div className="human-message-content message-text">
                    <div className="whitespace-pre-wrap">
                      {contentString}
                    </div>
                  </div>
                ) : null}
              </div>
            )}

            <div
              className={cn(
                "flex items-center gap-2 transition-opacity message-actions",
                "opacity-0 group-focus-within:opacity-100 group-hover:opacity-100",
                isEditing && "opacity-100",
              )}
            >
              <BranchSwitcher
                branch={meta?.branch}
                branchOptions={meta?.branchOptions}
                onSelect={(branch) => thread.setBranch(branch)}
                isLoading={isLoading}
              />
              <CommandBar
                isLoading={isLoading}
                content={contentString}
                isEditing={isEditing}
                setIsEditing={(c) => {
                  if (c) {
                    setValue(contentString);
                  }
                  setIsEditing(c);
                }}
                handleSubmitEdit={handleSubmitEdit}
                isHumanMessage={true}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
