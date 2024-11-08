-- luacheck: globals vim

vim.g.use_nerd_icons = true

return {
  kind = {
    Class = " ",
    Color = " ",
    Constant = " ",
    Constructor = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = "󰊕",
    Interface = " ",
    Keyword = " ",
    Method = " ",
    Misc = " ",
    Module = " ",
    Operator = " ",
    Property = " ",
    Reference = " ",
    Snippet = " ",
    Struct = " ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = " ",
  },
  type = {
    Array = " ",
    Boolean = " ",
    Number = " ",
    Object = " ",
    String = " ",
  },
  documents = {
    Code = "▣",
    File = " ",
    Files = " ",
    Folder = " ",
    OpenFolder = " ",
    Symlink = "",
  },
  tree = {
    EmptyFolder = "",
    EmptyOpenFolder = "",
    File = "",
    Folder = "",
    OpenFolder = "",
    Symlink = "",
    SymlinkArrow = " ➛ ",
    IndentCorner = "└ ",
    IndentEdge = "│ ",
  },
  git = {
    Add = " ",
    Branch = "",
    Diff = " ",
    GitLab = "",
    Ignore = " ",
    Logo = "",
    Merged = "",
    Mod = " ",
    Octoface = " ",
    Remove = " ",
    Rename = " ",
    Repo = " ",
    Sign = "│",
    SignBold = "┃",
    SignDelete = "",
    SignUntracked = "┋",
    Staged = "S",
    Unstaged = "",
    Untracked = "★",
  },
  ui = {
    ArrowClosed = " ",
    ArrowOpen = " ",
    BigCircle = " ",
    BigUnfilledCircle = " ",
    BoldDividerLeft = "",
    BoldDividerRight = "",
    BoldLineDashedMiddle = "┋",
    BoldLineLeft = "▎",
    BoldLineMiddle = "┃",
    BookMark = " ",
    Bug = " ",
    Calendar = " ",
    CaretRight = " ",
    Check = " ",
    ChevronRight = "",
    Circle = " ",
    Circular = "",
    Close = " ",
    CloudDownload = " ",
    Code = " ",
    Collapsed = "",
    Comment = " ",
    Dashboard = " ",
    Expanded = "",
    Fire = " ",
    Gear = "",
    GearOutline = " ",
    History = " ",
    Installed = "✓",
    Lightbulb = " ",
    List = " ",
    Lock = " ",
    NewFile = " ",
    Note = " ",
    NoteBook = " ",
    Package = " ",
    Pencil = " ",
    Pending = "➜",
    Pipe = "│",
    Project = " ",
    Search = " ",
    SignIn = " ",
    SignOut = " ",
    Table = " ",
    Telescope = " ",
    Terminal = "",
    TriangleShortArrowDown = "",
    TriangleShortArrowLeft = "",
    TriangleShortArrowRight = "",
    TriangleShortArrowUp = "",
    Uninstalled = "✗",
  },
  diagnostics = {
    Error = " ",
    Hint = " ",
    Information = " ",
    Question = " ",
    Warning = " ",
  },
  misc = {
    Package = " ",
    Robot = " ",
    Smiley = " ",
    Squirrel = " ",
    Tag = " ",
    Watch = " ",
  },
}
